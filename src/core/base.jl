function add_ref_dcgrid!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:it][_PM.pm_it_sym][:nw]

        # Delete unused dicts created by PowerModels for `dcline` components.
        # `dcline` components are converted to `branchdc` before calling this function.
        # Keeping unused dicts with similar names to the ones we use could be confusing.
        delete!(nw_ref, :arcs_from_dc)
        delete!(nw_ref, :arcs_to_dc)
        delete!(nw_ref, :arcs_dc)

        # Add dictionaries for DC components if they don't already exist
        if !haskey(nw_ref, :busdc)
            nw_ref[:busdc] = Dict{Int,Any}()
        end
        if !haskey(nw_ref, :branchdc)
            nw_ref[:branchdc] = Dict{Int,Any}()
        end
        if !haskey(nw_ref, :convdc)
            nw_ref[:convdc] = Dict{Int,Any}()
        end

        # Filter DC branches that are inactive or connected to nonexistent buses
        nw_ref[:branchdc] = Dict([x for x in nw_ref[:branchdc] if (
            any(values(x.second["status"]) .== 1) &&
            x.second["fbusdc"] in keys(nw_ref[:busdc]) &&
            x.second["tbusdc"] in keys(nw_ref[:busdc])
        )])

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(l, branch["fbusdc"], branch["tbusdc"]) for (l, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(l, branch["tbusdc"], branch["fbusdc"]) for (l, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]

        # Map DC arcs to their active conductors
        arcdc_conductors = Dict((l, i, j) => (Vector{Int}(), nw_ref[:branchdc][l]["conductors"]) for (l, i, j) in nw_ref[:arcsdc])
        nw_ref[:arcdc_conductors] = arcdc_conductors # Will be populated later

        # Map DC bus terminals to connected DC arc conductors
        busdc_terminal_arcdc_conductors = Dict([((bus["busdc_i"], c), Dict()) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
        for (l, i, j) in nw_ref[:arcsdc]
            if nw_ref[:branchdc][l]["conductors"] == 2
                terminals = _component_busdc_terminal_lookup[nw_ref[:branchdc][l]["connect_at"]]
            else
                terminals = 1:3
            end
            for (c, terminal) in enumerate(terminals)
                if !iszero(nw_ref[:branchdc][l]["status"][c])
                    push!(first(arcdc_conductors[(l, i, j)]), c)
                    push!(busdc_terminal_arcdc_conductors[(i, terminal)], (l, i, j) => c)
                end
            end
        end
        nw_ref[:busdc_terminal_arcdc_conductors] = busdc_terminal_arcdc_conductors

        # Filter converters that are inactive or connected to nonexistent buses
        nw_ref[:convdc] = Dict([x for x in nw_ref[:convdc] if (
            any(values(x.second["status"]) .== 1) &&
            x.second["busdc_i"] in keys(nw_ref[:busdc]) &&
            x.second["busac_i"] in keys(nw_ref[:bus])
        )])

        # Map AC bus to connected converters
        bus_convs = Dict([(i, []) for (i, bus) in nw_ref[:bus]])
        for (i, conv) in nw_ref[:convdc]
            push!(bus_convs[conv["busac_i"]], i)
        end
        nw_ref[:bus_convs] = bus_convs

        # Map converter to active poles on the AC side
        conv_acpoles = Dict(i => (findall(x -> !iszero(x), conv["status"]), conv["poles"]) for (i, conv) in nw_ref[:convdc])
        nw_ref[:conv_acpoles] = conv_acpoles # Will be populated later

        # Map converter to active poles on the DC side
        conv_dcpoles = Dict(i => (Vector{Int}(), conv["poles"]+1) for (i, conv) in nw_ref[:convdc])
        nw_ref[:conv_dcpoles] = conv_dcpoles # Will be populated later

        # Map DC bus terminal to connected converter poles
        busdc_terminal_conv_poles = Dict([((bus["busdc_i"], c), Dict()) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
        for (i, conv) in nw_ref[:convdc]
            bus = conv["busdc_i"]
            status_cond = findall(x->iszero(x), conv["status"])
            if conv["poles"] == 1
                terminals = _component_busdc_terminal_lookup[conv["connect_at"]]
            else
                terminals = 1:3
            end
            for (c, terminal) in enumerate(terminals)
                if !(c in status_cond)
                    push!(first(conv_dcpoles[i]), c)
                    push!(busdc_terminal_conv_poles[(bus, terminal)], i => c)
                end
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles

        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict([((bus["busdc_i"], c), Int[]) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
        for (i, conv) in nw_ref[:convdc]
            bus = conv["busdc_i"]
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[(bus, 3)], i) # (bus, 3) for selecting 3rd terminal of the relevant dc bus whereas i is for selecting the variable
            end
        end
        nw_ref[:busdc_grounded_convs] = busdc_grounded_convs

        # DC reference buses
        ref_buses_dc = Dict{Int,Any}()
        for (k, v) in nw_ref[:convdc]
            if v["type_dc"] == 2
                ref_buses_dc[k] = v
            end
        end
        if length(ref_buses_dc) == 0
            for (k, v) in nw_ref[:convdc]
                if v["type_ac"] == 2
                    ref_buses_dc[k] = v
                end
            end
            Memento.warn(_PM._LOGGER, "no reference DC bus found, setting reference bus based on AC bus type")
        end
        if length(ref_buses_dc) > 1
            ref_buses_warn = ""
            for (rb) in keys(ref_buses_dc)
                ref_buses_warn = ref_buses_warn * "$rb, "
            end
            Memento.warn(_PM._LOGGER, "multiple reference buses found, i.e. " * ref_buses_warn * "this can cause infeasibility if they are in the same connected component")
        end
        nw_ref[:ref_buses_dc] = ref_buses_dc

        # Warn if there are converters with power fixed on both sides
        for (c, conv) in nw_ref[:convdc]
            if conv["type_dc"] == 1 && conv["type_ac"] in (1,2)
                Memento.warn(_PM._LOGGER, "For converter $c is chosen P is fixed on AC and DC side. This can lead to infeasibility in the PF problem.")
            end
        end
    end
end

"compute bus pair level structures"
function buspair_parameters_dc(arcs_dcgrid_from, branches, buses)
    buspair_indexes = collect(Set([(i, j) for (l, i, j) in arcs_dcgrid_from]))

    bp_branch = Dict([(bp, Inf) for bp in buspair_indexes])

    for (l, branch) in branches
        i = branch["fbusdc"]
        j = branch["tbusdc"]

        bp_branch[(i, j)] = min(bp_branch[(i, j)], l)
    end

    buspairs = Dict([((i, j), Dict(
        "branch" => bp_branch[(i, j)],
        "vm_fr_min" => buses[i]["Vdcmin"],
        "vm_fr_max" => buses[i]["Vdcmax"],
        "vm_to_min" => buses[j]["Vdcmin"],
        "vm_to_max" => buses[j]["Vdcmax"]
    )) for (i, j) in buspair_indexes])

    return buspairs
end
