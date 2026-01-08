function add_ref_dcgrid!(ref::Dict{Symbol,<:Any}, nw_ref::Dict{String,<:Any})
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

        # Filter DC branches that are connected to nonexistent buses
        nw_ref[:branchdc] = Dict(b => branch for (b,branch) in nw_ref[:branchdc] if (
            branch["fbusdc"] in keys(nw_ref[:busdc]) &&
            branch["tbusdc"] in keys(nw_ref[:busdc])
        ))

        # Filter converters that are connected to nonexistent buses
        nw_ref[:convdc] = Dict(c => conv for (c,conv) in nw_ref[:convdc] if (
            conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            conv["busac_i"] in keys(nw_ref[:bus])
        ))

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]

        # Map DC bus to active terminals (as sets composed by "p", "r", and "n")
        nw_ref[:busdc_terminals] = Dict(
            # Assumption: all DC buses have all 3 terminals
            i => Set(("p", "r", "n"))
            for i in keys(nw_ref[:busdc])
        )

        # Map DC branch to active conductors (as sets composed by "p", "r", and "n")
        nw_ref[:branchdc_conductors] = Dict(
            b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
            for (b, branch) in nw_ref[:branchdc]
        )

        # Map converter to active poles (as sets composed by "p", "r", and "n")
        nw_ref[:convdc_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Same as previous one
        nw_ref[:convac_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Map AC bus to connected converter active poles
        #bus_conv_poles = Dict(
        #    i => Vector{Tuple{Int,String}}()
        #    for i in keys(nw_ref[:bus])
        #)
        #for (c,poles) in nw_ref[:convdc_poles]
        #    i = nw_ref[:convdc][c]["busac_i"]
        #    for pole in poles
        #        push!(bus_conv_poles[i], (c,pole))
        #    end
        #end
        #nw_ref[:bus_conv_poles] = bus_conv_poles


        bus_conv_poles = Dict(
            i => Dict()
            for i in keys(nw_ref[:bus])
        )
        
        for (c,poles) in nw_ref[:convdc_poles]
            i = nw_ref[:convdc][c]["busac_i"]
            bus_conv_poles[i] = Dict(c => Vector{String}())
            #bus_conv_poles["$i"]["$c"] => Vector{String}()
            for pole in poles
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles


        
        # Map DC bus terminal to connected active DC arcs
        busdc_terminal_arcsdc = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j) in nw_ref[:arcsdc]
            for conductor in nw_ref[:branchdc_conductors][l]
                terminal = conductor
                push!(busdc_terminal_arcsdc[i,terminal], (l,i,j))
            end
        end
        nw_ref[:busdc_terminal_arcsdc] = busdc_terminal_arcsdc
        println("busdc_terminal_arcsdc: ", nw_ref[:busdc_terminal_arcsdc])
        # Map DC bus terminal to connected converter active poles
        # ->  This was changed, let's see if it works 
        busdc_terminal_conv_poles = Dict(
            # b_id are buses and they can have up to three TERMINALS p,r,n
            b_id => Dict()
            for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_conv_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_conv_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end
        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "r" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"r"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"r"))
            end
            if "n" in poles
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles


        busdc_terminal_i_conv_dc_poles = Dict(
        # i are buses amnd they can have up to three TERMINALS p,r,n
        b_id => Dict()
        for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_i_conv_dc_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_i_conv_dc_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end

        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles && !("n" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "p" in poles && "n" in poles
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"r"))
            end
            if "n" in poles && !("p" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_i_conv_dc_poles] = busdc_terminal_i_conv_dc_poles

        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict(
            i => Vector{Int}()
            for i in keys(nw_ref[:busdc])
        )
        for (c,conv) in nw_ref[:convdc]
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[conv["busdc_i"]], c)
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

function add_ref_dcgrid_switch!(ref::Dict{Symbol,<:Any}, nw_ref::Dict{String,<:Any})
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

        # Filter DC branches that are connected to nonexistent buses
        nw_ref[:branchdc] = Dict(b => branch for (b,branch) in nw_ref[:branchdc] if (
            branch["fbusdc"] in keys(nw_ref[:busdc]) &&
            branch["tbusdc"] in keys(nw_ref[:busdc])
        ))

        # Filter converters that are connected to nonexistent buses
        nw_ref[:convdc] = Dict(c => conv for (c,conv) in nw_ref[:convdc] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]

        # Map DC bus to active terminals (as sets composed by "p", "r", and "n")
        nw_ref[:busdc_terminals] = Dict(
            # Assumption: all DC buses have all 3 terminals
            i => Set(("p", "r", "n"))
            for i in keys(nw_ref[:busdc])
        )


        # Map DC branch to active conductors (as sets composed by "p", "r", and "n")
        nw_ref[:branchdc_conductors] = Dict(
            b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
            for (b, branch) in nw_ref[:branchdc]
        )

        # Map converter to active poles (as sets composed by "p", "r", and "n")
        nw_ref[:convdc_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Same as previous one
        nw_ref[:convac_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Switch part
        nw_ref[:arcs_from_sw] = [(i,switch["f_bus"],switch["t_bus"]) for (i,switch) in nw_ref[:switch]]
        nw_ref[:arcs_to_sw]   = [(i,switch["t_bus"],switch["f_bus"]) for (i,switch) in nw_ref[:switch]]
        nw_ref[:arcs_sw] = [nw_ref[:arcs_from_sw]; nw_ref[:arcs_to_sw]]

        bus_arcs_sw = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_sw]
            push!(bus_arcs_sw[i], (l,i,j))
        end
        nw_ref[:bus_arcs_sw] = bus_arcs_sw

        # Map AC bus to connected converter active poles
        bus_conv_poles = Dict(
            i => Dict()
            for i in keys(nw_ref[:bus])
        )
        
        
        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                i = nw_ref[:convdc][c]["busac_i"][pole]
                println(" i is $(i)")
                if isempty(bus_conv_poles[i])
                    bus_conv_poles[i] = Dict(c => Vector{String}())    
                end
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles
        
        #=        
        for (c,poles) in nw_ref[:convdc_poles]
            i = nw_ref[:convdc][c]["busac_i"]
            bus_conv_poles[i] = Dict(c => Vector{String}())
            #bus_conv_poles["$i"]["$c"] => Vector{String}()
            for pole in poles
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles
        =#
        
        #for (c,poles) in nw_ref[:convdc_poles]
        #    i = nw_ref[:convdc][c]["busac_i"]
        #    bus_conv_poles[i] = Dict(c => Vector{String}())
        #    #bus_conv_poles["$i"]["$c"] => Vector{String}()
        #    for pole in poles
        #        push!(bus_conv_poles[i][c],pole)
        #    end
        #end
        #nw_ref[:bus_conv_poles] = bus_conv_poles

        # Map DC bus terminal to connected converter active poles
        # ->  This was changed, let's see if it works 
        busdc_terminal_conv_poles = Dict(
            # b_id are buses and they can have up to three TERMINALS p,r,n
            b_id => Dict()
            for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_conv_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_conv_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end
        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "r" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"r"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"r"))
            end
            if "n" in poles
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles


        busdc_terminal_i_conv_dc_poles = Dict(
        # i are buses amnd they can have up to three TERMINALS p,r,n
        b_id => Dict()
        for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_i_conv_dc_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_i_conv_dc_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end

        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles && !("n" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "p" in poles && "n" in poles
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"r"))
            end
            if "n" in poles && !("p" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_i_conv_dc_poles] = busdc_terminal_i_conv_dc_poles

        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict(
            i => Vector{Int}()
            for i in keys(nw_ref[:busdc])
        )
        for (c,conv) in nw_ref[:convdc]
            pole = first(keys(conv["Vdc"])) 
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[conv["busdc_i"][pole]], c)
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

function add_ref_dcgrid_switch_old!(ref::Dict{Symbol,<:Any}, nw_ref::Dict{String,<:Any})
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

        # Filter DC branches that are connected to nonexistent buses
        nw_ref[:branchdc] = Dict(b => branch for (b,branch) in nw_ref[:branchdc] if (
            branch["fbusdc"] in keys(nw_ref[:busdc]) &&
            branch["tbusdc"] in keys(nw_ref[:busdc])
        ))

        # Filter converters that are connected to nonexistent buses
        nw_ref[:convdc] = Dict(c => conv for (c,conv) in nw_ref[:convdc] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]

        # Map DC bus to active terminals (as sets composed by "p", "r", and "n")
        nw_ref[:busdc_terminals] = Dict(
            # Assumption: all DC buses have all 3 terminals
            i => Set(("p", "r", "n"))
            for i in keys(nw_ref[:busdc])
        )


        # Map DC branch to active conductors (as sets composed by "p", "r", and "n")
        nw_ref[:branchdc_conductors] = Dict(
            b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
            for (b, branch) in nw_ref[:branchdc]
        )

        # Map converter to active poles (as sets composed by "p", "r", and "n")
        nw_ref[:convdc_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Same as previous one
        nw_ref[:convac_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Switch part
        nw_ref[:arcs_from_sw] = [(i,switch["f_bus"],switch["t_bus"]) for (i,switch) in nw_ref[:switch]]
        nw_ref[:arcs_to_sw]   = [(i,switch["t_bus"],switch["f_bus"]) for (i,switch) in nw_ref[:switch]]
        nw_ref[:arcs_sw] = [nw_ref[:arcs_from_sw]; nw_ref[:arcs_to_sw]]

        bus_arcs_sw = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_sw]
            push!(bus_arcs_sw[i], (l,i,j))
        end
        nw_ref[:bus_arcs_sw] = bus_arcs_sw

        # Map AC bus to connected converter active poles
        bus_conv_poles = Dict(
            i => Dict()
            for i in keys(nw_ref[:bus])
        )
        
        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                i = nw_ref[:convdc][c]["busac_i"][pole]
                println(" i is $(i)")
                if isempty(bus_conv_poles[i])
                    bus_conv_poles[i] = Dict(c => Vector{String}())    
                end
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles

        
        
        #for (c,poles) in nw_ref[:convdc_poles]
        #    i = nw_ref[:convdc][c]["busac_i"]
        #    bus_conv_poles[i] = Dict(c => Vector{String}())
        #    #bus_conv_poles["$i"]["$c"] => Vector{String}()
        #    for pole in poles
        #        push!(bus_conv_poles[i][c],pole)
        #    end
        #end
        #nw_ref[:bus_conv_poles] = bus_conv_poles

        # Map DC bus terminal to connected active DC arcs
        busdc_terminal_arcsdc = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j) in nw_ref[:arcsdc]
            for conductor in nw_ref[:branchdc_conductors][l]
                terminal = conductor
                push!(busdc_terminal_arcsdc[i,terminal], (l,i,j))
            end
        end
        nw_ref[:busdc_terminal_arcsdc] = busdc_terminal_arcsdc

        # Map DC bus terminal to connected converter active poles
        # ->  This was changed, let's see if it works 
        busdc_terminal_conv_poles = Dict(
            # b_id are buses and they can have up to three TERMINALS p,r,n
            b_id => Dict()
            for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_conv_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_conv_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end
        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "r" in poles
                push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"r"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"r"))
            end
            if "n" in poles
                push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles


        busdc_terminal_i_conv_dc_poles = Dict(
        # i are buses amnd they can have up to three TERMINALS p,r,n
        b_id => Dict()
        for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_i_conv_dc_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_i_conv_dc_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end

        for (c,poles) in nw_ref[:convdc_poles]
            b_id = nw_ref[:convdc][c]["busdc_i"]
            if "p" in poles && !("n" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"p"))
            end
            if "p" in poles && "n" in poles
                push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"r"))
            end
            if "n" in poles && !("p" in poles)
                push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"n"))
                push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
            end
        end
        nw_ref[:busdc_terminal_i_conv_dc_poles] = busdc_terminal_i_conv_dc_poles

        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict(
            i => Vector{Int}()
            for i in keys(nw_ref[:busdc])
        )
        for (c,conv) in nw_ref[:convdc]
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[conv["busdc_i"]], c)
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

function add_ref_dcgrid_dcswitch!(ref::Dict{Symbol,<:Any}, nw_ref::Dict{String,<:Any})
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
        if !haskey(nw_ref, :dcswitch)
            nw_ref[:dcswitch] = Dict{Int,Any}()
        end

        # Filter DC branches that are connected to nonexistent buses
        nw_ref[:branchdc] = Dict(b => branch for (b,branch) in nw_ref[:branchdc] if (
            branch["fbusdc"] in keys(nw_ref[:busdc]) &&
            branch["tbusdc"] in keys(nw_ref[:busdc]))
        )

        # Filter converters that are connected to nonexistent buses
        nw_ref[:convdc] = Dict(c => conv for (c,conv) in nw_ref[:convdc] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )

        nw_ref[:dcswitch] = Dict(sw_id => sw for (sw_id,sw) in nw_ref[:dcswitch] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )
        println("dcswitch: ", nw_ref[:dcswitch])

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]
        println("arcsdc: ", nw_ref[:arcsdc])
        # Map DC bus to active terminals (as sets composed by "p", "r", and "n")
        nw_ref[:busdc_terminals] = Dict(
            # Assumption: all DC buses have all 3 terminals
            i => Set(("p", "r", "n"))
            for i in keys(nw_ref[:busdc])
        )

        # Map DC branch to active conductors (as sets composed by "p", "r", and "n")
        nw_ref[:branchdc_conductors] = Dict(
            b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
            for (b, branch) in nw_ref[:branchdc]
        )

        nw_ref[:dcswitch_conductors] = Dict(
            sw_id => "$(sw["terminal"])"
            for (sw_id, sw) in nw_ref[:dcswitch]
        )

        # Map converter to active poles (as sets composed by "p", "r", and "n")
        nw_ref[:convdc_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Same as previous one
        nw_ref[:convac_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Map AC bus to connected converter active poles
        bus_conv_poles = Dict(
            i => Dict()
            for i in keys(nw_ref[:bus])
        )
        
        for (c,poles) in nw_ref[:convdc_poles]
            i = nw_ref[:convdc][c]["busac_i"]
            bus_conv_poles[i] = Dict(c => Vector{String}())
            #bus_conv_poles["$i"]["$c"] => Vector{String}()
            for pole in poles
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles


        ## Switch part
        nw_ref[:arcs_from_sw_dc] = [(i,switch["f_busdc"],switch["t_busdc"],switch["terminal"]) for (i,switch) in nw_ref[:dcswitch]]
        nw_ref[:arcs_to_sw_dc]   = [(i,switch["t_busdc"],switch["f_busdc"],switch["terminal"]) for (i,switch) in nw_ref[:dcswitch]]
        nw_ref[:arcs_sw_dc] = [nw_ref[:arcs_from_sw_dc]; nw_ref[:arcs_to_sw_dc]]

        bus_arcs_sw_dc = Dict((i, Tuple{Int,Int,Int,String}[]) for (i,bus) in nw_ref[:busdc])
        for (l,i,j,cond) in nw_ref[:arcs_sw_dc]
            push!(bus_arcs_sw_dc[i], (l,i,j,cond))
        end
        nw_ref[:bus_arcs_sw_dc] = bus_arcs_sw_dc

        # Map DC bus terminal to connected active DC arcs
        busdc_terminal_arcsdc = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j) in nw_ref[:arcsdc]
            for conductor in nw_ref[:branchdc_conductors][l]
                terminal = conductor
                push!(busdc_terminal_arcsdc[i,terminal], (l,i,j))
            end
        end
        nw_ref[:busdc_terminal_arcsdc] = busdc_terminal_arcsdc
        
        
        busdc_terminal_arcsdc_sw = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int,String}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j,conductor) in nw_ref[:arcs_sw_dc]
            for (bus,terminal) in keys(busdc_terminal_arcsdc_sw)
                if i == bus && conductor == terminal
                    push!(busdc_terminal_arcsdc_sw[bus,terminal], (l,i,j,conductor))
                end
            end
        end
        nw_ref[:busdc_terminal_arcsdc_sw] = busdc_terminal_arcsdc_sw
        
        # Map DC bus terminal to connected converter active poles
        # ->  This was changed, let's see if it works 
        busdc_terminal_conv_poles = Dict(
            # b_id are buses and they can have up to three TERMINALS p,r,n
            b_id => Dict()
            for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_conv_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_conv_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end
        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                b_id = nw_ref[:convdc][c]["busdc_i"][pole]
                if "p" == pole
                    push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"p"))
                end
                if "r" == pole
                    push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"r"))
                    push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"r"))
                end
                if "n" == pole
                    push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"n"))
                    push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"n"))
                end
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles
        println("busdc_terminal_conv_poles: ", nw_ref[:busdc_terminal_conv_poles])

        busdc_terminal_i_conv_dc_poles = Dict(
        # i are buses amnd they can have up to three TERMINALS p,r,n
        b_id => Dict()
        for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_i_conv_dc_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_i_conv_dc_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end

        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                b_id = nw_ref[:convdc][c]["busdc_i"][pole]
                if "p" in poles && !("n" in poles)
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"p"))
                end
                if "p" in poles && "n" in poles
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"r"))
                end
                if "n" in poles && !("p" in poles)
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"n"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                end
            end
        end
        nw_ref[:busdc_terminal_i_conv_dc_poles] = busdc_terminal_i_conv_dc_poles
        
        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict(
            i => Vector{Int}()
            for i in keys(nw_ref[:busdc])
        )
        for (c,conv) in nw_ref[:convdc]
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[conv["busdc_i"][first(keys(conv["busdc_i"]))]], c)
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

function add_ref_dcgrid_dcswitch_corrected!(ref::Dict{Symbol,<:Any}, nw_ref::Dict{String,<:Any})
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
        if !haskey(nw_ref, :dcswitch)
            nw_ref[:dcswitch] = Dict{Int,Any}()
        end

        # Filter DC branches that are connected to nonexistent buses
        nw_ref[:branchdc] = Dict(b => branch for (b,branch) in nw_ref[:branchdc] if (
            branch["fbusdc"] in keys(nw_ref[:busdc]) &&
            branch["tbusdc"] in keys(nw_ref[:busdc]))
        )

        # Filter converters that are connected to nonexistent buses
        nw_ref[:convdc] = Dict(c => conv for (c,conv) in nw_ref[:convdc] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )

        nw_ref[:dcswitch] = Dict(sw_id => sw for (sw_id,sw) in nw_ref[:dcswitch] #if (
            #conv["busdc_i"] in keys(nw_ref[:busdc]) &&
            #conv["busac_i"][pole] in keys(nw_ref[:bus]))
        )
        println("dcswitch: ", nw_ref[:dcswitch])

        # DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
        nw_ref[:arcsdc_from] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc_to]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in nw_ref[:branchdc]]
        nw_ref[:arcsdc]      = [nw_ref[:arcsdc_from]; nw_ref[:arcsdc_to]]
        println("arcsdc: ", nw_ref[:arcsdc])
        # Map DC bus to active terminals (as sets composed by "p", "r", and "n")
        nw_ref[:busdc_terminals] = Dict(
            # Assumption: all DC buses have all 3 terminals
            i => Set(("p", "r", "n"))
            for i in keys(nw_ref[:busdc])
        )

        # Map DC branch to active conductors (as sets composed by "p", "r", and "n")
        nw_ref[:branchdc_conductors] = Dict(
            b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
            for (b, branch) in nw_ref[:branchdc]
        )

        nw_ref[:dcswitch_conductors] = Dict(
            sw_id => "$(sw["terminal"])"
            for (sw_id, sw) in nw_ref[:dcswitch]
        )

        # Map converter to active poles (as sets composed by "p", "r", and "n")
        nw_ref[:convdc_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Same as previous one
        nw_ref[:convac_poles] = Dict(
            c => Set(pole for (pole, status) in conv["status"] if status == 1)
            for (c, conv) in nw_ref[:convdc]
        )

        # Map AC bus to connected converter active poles
        bus_conv_poles = Dict(
            i => Dict()
            for i in keys(nw_ref[:bus])
        )
        
        for (c,poles) in nw_ref[:convdc_poles]
            i = nw_ref[:convdc][c]["busac_i"]
            bus_conv_poles[i] = Dict(c => Vector{String}())
            #bus_conv_poles["$i"]["$c"] => Vector{String}()
            for pole in poles
                push!(bus_conv_poles[i][c],pole)
            end
        end
        nw_ref[:bus_conv_poles] = bus_conv_poles


        ## Switch part
        nw_ref[:arcs_from_sw_dc] = [(i,switch["f_busdc"],switch["t_busdc"],switch["terminal"]) for (i,switch) in nw_ref[:dcswitch]]
        nw_ref[:arcs_to_sw_dc]   = [(i,switch["t_busdc"],switch["f_busdc"],switch["terminal"]) for (i,switch) in nw_ref[:dcswitch]]
        nw_ref[:arcs_sw_dc] = [nw_ref[:arcs_from_sw_dc]; nw_ref[:arcs_to_sw_dc]]

        bus_arcs_sw_dc = Dict((i, Tuple{Int,Int,Int,String}[]) for (i,bus) in nw_ref[:busdc])
        for (l,i,j,cond) in nw_ref[:arcs_sw_dc]
            push!(bus_arcs_sw_dc[i], (l,i,j,cond))
        end
        nw_ref[:bus_arcs_sw_dc] = bus_arcs_sw_dc

        # Map DC bus terminal to connected active DC arcs
        busdc_terminal_arcsdc = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j) in nw_ref[:arcsdc]
            for conductor in nw_ref[:branchdc_conductors][l]
                terminal = conductor
                push!(busdc_terminal_arcsdc[i,terminal], (l,i,j))
            end
        end
        nw_ref[:busdc_terminal_arcsdc] = busdc_terminal_arcsdc
        
        
        busdc_terminal_arcsdc_sw = Dict(
            (i,t) => Vector{Tuple{Int,Int,Int,String}}()
            for (i,terminals) in nw_ref[:busdc_terminals]
            for t in terminals
        )
        for (l,i,j,conductor) in nw_ref[:arcs_sw_dc]
            for (bus,terminal) in keys(busdc_terminal_arcsdc_sw)
                if i == bus && conductor == terminal
                    push!(busdc_terminal_arcsdc_sw[bus,terminal], (l,i,j,conductor))
                end
            end
        end
        nw_ref[:busdc_terminal_arcsdc_sw] = busdc_terminal_arcsdc_sw
        
        # Map DC bus terminal to connected converter active poles
        # ->  This was changed, let's see if it works 
        busdc_terminal_conv_poles = Dict(
            # b_id are buses and they can have up to three TERMINALS p,r,n
            b_id => Dict()
            for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_conv_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_conv_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end
        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                b_id = nw_ref[:convdc][c]["busdc_i"][pole]
                if "p" == pole
                    push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"p"))
                end
                if "r" == pole
                    push!(busdc_terminal_conv_poles[b_id]["p"],(Int64(c),"r"))
                    push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"r"))
                end
                if "n" == pole
                    push!(busdc_terminal_conv_poles[b_id]["r"],(Int64(c),"n"))
                    push!(busdc_terminal_conv_poles[b_id]["n"],(Int64(c),"n"))
                end
            end
        end
        nw_ref[:busdc_terminal_conv_poles] = busdc_terminal_conv_poles


        busdc_terminal_i_conv_dc_poles = Dict(
        # i are buses amnd they can have up to three TERMINALS p,r,n
        b_id => Dict()
        for b_id in keys(nw_ref[:busdc])
        )
        for b_id in keys(busdc_terminal_i_conv_dc_poles)
            for terminal in keys(nw_ref[:busdc][b_id]["Vdc"])
                busdc_terminal_i_conv_dc_poles[b_id][terminal] = Vector{Tuple{Int,String}}()
            end
        end

        for (c,poles) in nw_ref[:convdc_poles]
            for pole in poles
                b_id = nw_ref[:convdc][c]["busdc_i"][pole]
                if "p" in poles && !("n" in poles)
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"p"))
                end
                if "p" in poles && "n" in poles
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["p"],(Int64(c),"p"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"r"))
                end
                if "n" in poles && !("p" in poles)
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["r"],(Int64(c),"n"))
                    push!(busdc_terminal_i_conv_dc_poles[b_id]["n"],(Int64(c),"n"))
                end
            end
        end
        nw_ref[:busdc_terminal_i_conv_dc_poles] = busdc_terminal_i_conv_dc_poles
        
        # Map DC bus to connected grounded converters
        busdc_grounded_convs = Dict(
            i => Vector{Int}()
            for i in keys(nw_ref[:busdc])
        )
        for (c,conv) in nw_ref[:convdc]
            if conv["ground_type"] == 1
                push!(busdc_grounded_convs[conv["busdc_i"][first(keys(conv["busdc_i"]))]], c)
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
function buspair_parameters_dc(arcsdc_from, branches, buses)
    buspair_indexes = collect(Set([(i, j) for (l, i, j) in arcsdc_from]))

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


# Extend PowerModels' reference functions with methods for multiconductor quantities

_PM.ref(pm::_PM.AbstractPowerModel, nw::Int, key::Symbol, idx, param::String, conductor::String) = _IM.ref(pm, _PM.pm_it_sym, nw, key, idx, param)[conductor]
_PM.ref(pm::_PM.AbstractPowerModel, key::Symbol, idx, param::String, conductor::String; nw::Int=nw_id_default) = _IM.ref(pm, _PM.pm_it_sym, key, idx, param; nw = nw)[conductor]

_PM.var(pm::_PM.AbstractPowerModel, nw::Int, key::Symbol, idx, conductor::String) = _IM.var(pm, _PM.pm_it_sym, nw, key, idx)[conductor]
_PM.var(pm::_PM.AbstractPowerModel, key::Symbol, idx, conductor::String; nw::Int=nw_id_default) = _IM.var(pm, _PM.pm_it_sym, key, idx; nw = nw)[conductor]

_PM.con(pm::_PM.AbstractPowerModel, nw::Int, key::Symbol, idx, conductor::String) = _IM.con(pm, _PM.pm_it_sym, nw, key, idx)[conductor]
_PM.con(pm::_PM.AbstractPowerModel, key::Symbol, idx, conductor::String; nw::Int=nw_id_default) = _IM.con(pm, _PM.pm_it_sym, key, idx; nw = nw)[conductor]

_PM.sol(pm::_PM.AbstractPowerModel, nw::Int, key::Symbol, idx, conductor::String) = _IM.sol(pm, _PM.pm_it_sym, nw, key, idx)[conductor]
_PM.sol(pm::_PM.AbstractPowerModel, key::Symbol, idx, conductor::String; nw::Int=nw_id_default) = _IM.sol(pm, _PM.pm_it_sym, key, idx; nw = nw)[conductor]

