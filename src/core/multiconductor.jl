"removing predefined conductor"

"Transforms single-conductor network data into multiconductor data"
function make_multiconductor!(data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
        for (i, nw_data) in data["nw"]
            _make_multiconductor!(nw_data)
        end
    else
        _make_multiconductor!(data)
    end
end

#TODO put names in the order of .m files so that they are easy to find. Everything that doesn't have a conductorwise choice to be
#in this field for now
"feild names that should not be multiconductor values"
const _conductorless = Set(["basekVdc", "source_id", "busdc_i", "grid", "index",
    "return_type", "confi", "return_z", "fbusdc", "tbusdc", "busac_i",
    "basekVac", "type_dc", "filter", "reactor", "transformer", "type_ac", "Vtar",
    "islcc", "ground_type", "line_confi", "connect_at", "conv_confi",
    "ground_z", "type_dc", "conductors", "status_p", "status_n", "status_r"])
#Assumed: control modes and setpoints are not per conductor. Can multiconductorin future.
# "P_g", "Q_g", removed due to conv set point. Should be tackled differently if multiconductor of AC is considered
# "dVdcset", "Vdcset", removed for giving pf setpoints
#"Pdcset", "droop",

"only dc side data"
const _DCdata = ["busdc", "convdc", "branchdc"]
const _DCstatus = ["status_p", "status_n", "status_r"]

"feild names that should become multiconductor matrix not arrays"
const _conductor_matrix = Set(["br_r", "br_x", "rc", "xc", "rtf", "xtf", "bf"])

function _make_multiconductor!(data::Dict{String,<:Any})

    data["conductors_dc"] = true

    for (key, item) in data
        if key in _DCdata
            if isa(item, Dict{String,Any})
                for (item_id, item_data) in item
                    if isa(item_data, Dict{String,Any})
                        item_ref_data = Dict{String,Any}()
                        conductors = conductorsDC_number(item_data)
                        item_data["conductors"] = conductors
                        for (param, value) in item_data
                            if param in _conductorless
                                item_ref_data[param] = value
                            elseif param == "status"
                                item_ref_data[param] = conductorsDC_status(item_data) .* item_data[param]
                            elseif key == "busdc" && in(param, ["Vdcmin", "Vdcmax"])
                                item_ref_data[param] = terminalDC_voltage_bound(item_data, param)
                            elseif key == "busdc" && param == "Vdc"
                                item_ref_data[param] = terminalDC_voltage_start(item_data, param)
                            else
                                item_ref_data[param] = fill(value, conductors)
                                # Adjust resistance of branchdc metallic return
                                if key == "branchdc" && param == "r"
                                    item_ref_data[param][conductors] = item_data["return_z"]
                                end
                            end
                        end
                        item[item_id] = item_ref_data
                    end
                end
            else
                #root non-dict items
            end
        end
    end
end

function conductorsDC_number(item_data::Dict{String,<:Any})
    if haskey(item_data, "conv_confi")
        if item_data["conv_confi"] == 1 #monopolar coverter
            conductors = 1
        else
            conductors = 2
        end
    elseif haskey(item_data, "line_confi")
        if item_data["line_confi"] == 1 #monopolar/symmetrical dc line
            conductors = 2
        else
            conductors = 3
        end
    else
        conductors = 3  # for buses
    end
    return conductors
end

"Generate vector of multi-conductor status states for `convdc` and `branchdc` components"
function conductorsDC_status(item_data::Dict{String,<:Any})
    poles = Vector{Int}()
    if haskey(item_data, "conv_confi")
        if item_data["conv_confi"] == 1
            append!(poles, first(_component_busdc_terminal_lookup[item_data["connect_at"]], 1))
        else
            append!(poles, 1:2)
        end
    elseif haskey(item_data, "line_confi")
        if item_data["line_confi"] == 1
            append!(poles, _component_busdc_terminal_lookup[item_data["connect_at"]])
        else
            append!(poles, 1:3)
        end
    end
    return [item_data[key] for key in _DCstatus[poles]]
end

"Adjust voltage bound for multi-conductor `busdc` terminals"
function terminalDC_voltage_bound(item_data::Dict{String,<:Any}, param::String)
    atol = item_data[param] - 1
    return atol .+ [1, -1, 0]
end

"Adjust voltage start value for multi-conductor `busdc` terminals"
function terminalDC_voltage_start(item_data::Dict{String,<:Any}, param::String)
    v = item_data[param]
    return [v, -v, 0]
end
