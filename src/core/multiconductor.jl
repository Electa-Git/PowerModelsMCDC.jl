"Field names that do not have multiconductor values"
const _conductorless = Set([
        # Multiple components
        "busdc_i", "connect_at", "status_p", "status_r", "status_n", "index", "source_id",
        "conductors",
        # DC bus
        "grid", "basekVdc",
        # DC branch
        "fbusdc", "tbusdc", "line_confi", "return_type", "return_z",
        # Converter
        "busac_i", "type_dc", "type_ac", "islcc", "Vtar", "transformer", "filter",
        "reactor", "basekVac", "conv_confi", "ground_type", "ground_z"
    ])

"Names of multiconductor status parameters"
const _mc_status = ["status_p", "status_n", "status_r"]

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

function _make_multiconductor!(data::Dict{String,<:Any})
    if haskey(data, "busdc")
        _make_multiconductor_busdc!(data["busdc"])
    end
    if haskey(data, "branchdc")
        _make_multiconductor_branchdc!(data["branchdc"])
    end
    if haskey(data, "convdc")
        _make_multiconductor_convdc!(data["convdc"])
    end
end

function _make_multiconductor_busdc!(busdc_dict::Dict{String,<:Any})
    for (b, busdc) in busdc_dict
        mc_busdc = Dict{String,Any}()
        conductors = 3
        busdc["conductors"] = conductors
        for (param, value) in busdc
            if param in _conductorless
                mc_busdc[param] = value
            elseif param == "status"
                mc_busdc[param] = conductorsDC_status(busdc) .* busdc[param]
            elseif param in ["Vdcmin", "Vdcmax"]
                mc_busdc[param] = terminalDC_voltage_bound(busdc, param)
            elseif param == "Vdc"
                mc_busdc[param] = terminalDC_voltage_start(busdc, param)
            else
                mc_busdc[param] = fill(value, conductors)
            end
        end
        busdc_dict[b] = mc_busdc
    end
end

function _make_multiconductor_branchdc!(branchdc_dict::Dict{String,<:Any})
    for (b, branchdc) in branchdc_dict
        mc_branchdc = Dict{String,Any}()
        if branchdc["line_confi"] == 1 # monopolar (symmetric or asymmetric)
            conductors = 2
        else # bipolar
            conductors = 3
        end
        branchdc["conductors"] = conductors
        for (param, value) in branchdc
            if param in _conductorless
                mc_branchdc[param] = value
            elseif param == "status"
                mc_branchdc[param] = conductorsDC_status(branchdc) .* branchdc[param]
            else
                mc_branchdc[param] = fill(value, conductors)
                # Adjust resistance of branchdc metallic return
                if param == "r"
                    mc_branchdc[param][conductors] = branchdc["return_z"]
                end
            end
        end
        branchdc_dict[b] = mc_branchdc
    end
end

function _make_multiconductor_convdc!(convdc_dict::Dict{String,<:Any})
    for (c, convdc) in convdc_dict
        mc_convdc = Dict{String,Any}()
        if convdc["conv_confi"] == 1 # monopolar (symmetric or asymmetric)
            conductors = 1
        else # bipolar
            conductors = 2
        end
        convdc["conductors"] = conductors
        for (param, value) in convdc
            if param in _conductorless
                mc_convdc[param] = value
            elseif param == "status"
                mc_convdc[param] = conductorsDC_status(convdc) .* convdc[param]
            else
                mc_convdc[param] = fill(value, conductors)
            end
        end
        convdc_dict[c] = mc_convdc
    end
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
    return [item_data[key] for key in _mc_status[poles]]
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
