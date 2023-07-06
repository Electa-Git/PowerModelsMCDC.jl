function add_ref_dcgrid!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:it][_PM.pm_it_sym][:nw]
        if haskey(nw_ref, :convdc)
            #Filter converters & DC branches with status 0 as well as wrong bus numbers
            nw_ref[:convdc] = Dict([x for x in nw_ref[:convdc] if (x.second["status"] == 1 && x.second["busdc_i"] in keys(nw_ref[:busdc]) && x.second["busac_i"] in keys(nw_ref[:bus]))])
            nw_ref[:branchdc] = Dict([x for x in nw_ref[:branchdc] if (x.second["status"] == 1 && x.second["fbusdc"] in keys(nw_ref[:busdc]) && x.second["tbusdc"] in keys(nw_ref[:busdc]))])

            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid_from] = [(i, branch["fbusdc"], branch["tbusdc"]) for (i, branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid_to] = [(i, branch["tbusdc"], branch["fbusdc"]) for (i, branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid] = [nw_ref[:arcs_dcgrid_from]; nw_ref[:arcs_dcgrid_to]]
            nw_ref[:arcs_conv_acdc] = [(i, conv["busac_i"], conv["busdc_i"]) for (i, conv) in nw_ref[:convdc]]
            #bus arcs of the DC grid
            bus_arcs_dcgrid = Dict([(bus["busdc_i"], []) for (i, bus) in nw_ref[:busdc]])
            for (l, i, j) in nw_ref[:arcs_dcgrid]
                push!(bus_arcs_dcgrid[i], (l, i, j))
            end
            nw_ref[:bus_arcs_dcgrid] = bus_arcs_dcgrid

            # bus_line_conn = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            # for (l,i,j) in nw_ref[:arcs_dcgrid]
            #     push!(bus_line_conn[i], l)
            # end
            # nw_ref[:bus_line_conn] = bus_line_conn
            # display("bus_line_conn")
            # display(bus_line_conn)

            #bus arcs of the DC grid - conductor connections
            # display("nw_ref_busdc")
            bus_arcs_dcgrid_cond = Dict([((bus["busdc_i"], c), Dict()) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
            # display(bus_arcs_dcgrid_cond)

            for (l, i, j) in nw_ref[:arcs_dcgrid]
                if nw_ref[:branchdc][l]["line_confi"] == 1
                    if nw_ref[:branchdc][l]["connect_at"] == 0
                        push!(bus_arcs_dcgrid_cond[(i, 1)], (l, i, j) => 1) # (i, 1) for connection and  (l,i,j) =>1 for selecting line variable
                        push!(bus_arcs_dcgrid_cond[(i, 2)], (l, i, j) => 2)  # 1, 2 and 3 are the positive, negative and neutral terminals of a DC bus, respectively 
                    elseif nw_ref[:branchdc][l]["connect_at"] == 1
                        push!(bus_arcs_dcgrid_cond[(i, 1)], (l, i, j) => 1)
                        push!(bus_arcs_dcgrid_cond[(i, 3)], (l, i, j) => 2)
                    elseif nw_ref[:branchdc][l]["connect_at"] == 2
                        push!(bus_arcs_dcgrid_cond[(i, 2)], (l, i, j) => 1)
                        push!(bus_arcs_dcgrid_cond[(i, 3)], (l, i, j) => 2)
                    end
                elseif nw_ref[:branchdc][l]["line_confi"] == 2
                    push!(bus_arcs_dcgrid_cond[(i, 1)], (l, i, j) => 1)
                    push!(bus_arcs_dcgrid_cond[(i, 2)], (l, i, j) => 2)
                    push!(bus_arcs_dcgrid_cond[(i, 3)], (l, i, j) => 3)
                end
                # end
            end
            nw_ref[:bus_arcs_dcgrid_cond] = bus_arcs_dcgrid_cond

            # bus_convs for AC side power injection of DC converters
            bus_convs_ac = Dict([(i, []) for (i, bus) in nw_ref[:bus]])
            for (i, conv) in nw_ref[:convdc]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac] = bus_convs_ac

            # bus_convs for AC side power injection of DC converters
            bus_convs_dc = Dict([(bus["busdc_i"], []) for (i, bus) in nw_ref[:busdc]])
            for (i, conv) in nw_ref[:convdc]
                push!(bus_convs_dc[conv["busdc_i"]], i)
            end
            nw_ref[:bus_convs_dc] = bus_convs_dc

            # bus_convs for AC side power injection of DC converters - conductor references
            bus_convs_dc_cond = Dict([((bus["busdc_i"], c), Dict()) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
            for (i, conv) in nw_ref[:convdc]
                bus = conv["busdc_i"]
                if conv["conv_confi"] == 1
                    if conv["connect_at"] == 0
                        push!(bus_convs_dc_cond[(bus, 1)], i => 1)
                        push!(bus_convs_dc_cond[(bus, 2)], i => 2)
                    elseif conv["connect_at"] == 1
                        push!(bus_convs_dc_cond[(bus, 1)], i => 1)
                        push!(bus_convs_dc_cond[(bus, 3)], i => 2)
                    elseif conv["connect_at"] == 2
                        push!(bus_convs_dc_cond[(bus, 2)], i => 1)
                        push!(bus_convs_dc_cond[(bus, 3)], i => 2) #'i' is for variable where as (bus,3) for connection
                    end
                elseif conv["conv_confi"] == 2
                    push!(bus_convs_dc_cond[(bus, 1)], i => 1)
                    push!(bus_convs_dc_cond[(bus, 2)], i => 2)
                    push!(bus_convs_dc_cond[(bus, 3)], i => 3)
                end
                # end
            end

            nw_ref[:bus_convs_dc_cond] = bus_convs_dc_cond

            # add dc ground as shunt
            bus_convs_grounding_shunt = Dict([((bus["busdc_i"], c), Int[]) for c in 1:3 for (i, bus) in nw_ref[:busdc]])
            for (i, conv) in nw_ref[:convdc]
                bus = conv["busdc_i"]
                if conv["ground_type"] == 1
                    push!(bus_convs_grounding_shunt[(bus, 3)], i) # (bus, 3) for selecting 3rd conductor of the relevant dc bus whereas i is for selecting the variable
                end
            end
            nw_ref[:bus_convs_grounding_shunt] = bus_convs_grounding_shunt

            # Add DC reference buses
            ref_buses_dc = Dict{String,Any}()
            for (k, v) in nw_ref[:convdc]
                if v["type_dc"] == 2
                    ref_buses_dc["$k"] = v
                end
            end

            if length(ref_buses_dc) == 0
                for (k, v) in nw_ref[:convdc]
                    if v["type_ac"] == 2
                        ref_buses_dc["$k"] = v
                    end
                end
                Memento.warn(_PM._LOGGER, "no reference DC bus found, setting reference bus based on AC bus type")
            end

            for (k, conv) in nw_ref[:convdc]
                conv_id = conv["index"]
                if conv["type_ac"] == 2 && conv["type_dc"] == 1
                    Memento.warn(_PM._LOGGER, "For converter $conv_id is chosen P is fixed on AC and DC side. This can lead to infeasibility in the PF problem.")
                elseif conv["type_ac"] == 1 && conv["type_dc"] == 1
                    Memento.warn(_PM._LOGGER, "For converter $conv_id is chosen P is fixed on AC and DC side. This can lead to infeasibility in the PF problem.")
                end
                convbus_ac = conv["busac_i"]
                # display(conv["Vmmax"])
                # if conv["Vmmax"] < nw_ref[:bus][convbus_ac]["vmin"]
                #     Memento.warn(_PM._LOGGER, "The maximum AC side voltage of converter $conv_id is smaller than the minimum AC bus voltage")
                # end
                # if conv["Vmmin"] > nw_ref[:bus][convbus_ac]["vmax"]
                #     Memento.warn(_PM._LOGGER, "The miximum AC side voltage of converter $conv_id is larger than the maximum AC bus voltage")
                # end
            end

            if length(ref_buses_dc) > 1
                ref_buses_warn = ""
                for (rb) in keys(ref_buses_dc)
                    ref_buses_warn = ref_buses_warn * rb * ", "
                end
                Memento.warn(_PM._LOGGER, "multiple reference buses found, i.e. " * ref_buses_warn * "this can cause infeasibility if they are in the same connected component")
            end


            # if haskey(pm.setting, "find_all_ac_grids") && pm.tetting["find_all_ac_grids"] == true
            #     ACgrids = find_all_ac_grids(nw_ref[:branch], nw_ref[:bus])
            #     for (i, grid) in ACgrids
            #         a = 0
            #         for (j, bus) in nw_ref[:ref_buses]
            #             if (bus["bus_i"] in grid["Buses"])
            #                 a = 1
            #             end
            #         end
            #         if a == 0
            #             Memento.warn(_PM._LOGGER, "Grid $i does not have any voltage reference bus, this might cause infeasibility")
            #         end
            #     end
            # end
            nw_ref[:ref_buses_dc] = ref_buses_dc
            nw_ref[:buspairsdc] = buspair_parameters_dc(nw_ref[:arcs_dcgrid_from], nw_ref[:branchdc], nw_ref[:busdc])
        else
            nw_ref[:convdc] = Dict{String,Any}()
            nw_ref[:busdc] = Dict{String,Any}()
            nw_ref[:branchdc] = Dict{String,Any}()
            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid] = Dict{String,Any}()
            nw_ref[:arcs_dcgrid_from] = Dict{String,Any}()
            nw_ref[:arcs_dcgrid_to] = Dict{String,Any}()
            nw_ref[:arcs_conv_acdc] = Dict{String,Any}()
            nw_ref[:bus_arcs_dcgrid] = Dict{String,Any}()
            bus_convs_ac = Dict([(i, []) for (i, bus) in nw_ref[:bus]])
            for (i, conv) in nw_ref[:convdc]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac] = bus_convs_ac
            nw_ref[:bus_convs_dc] = Dict{String,Any}()
            nw_ref[:ref_buses_dc] = Dict{String,Any}()
            nw_ref[:buspairsdc] = Dict{String,Any}()
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
