"Scalar DC bus parameters in Matpower format, to be replicated for each terminal"
const _busdc_uniform_parameters = Set(["Pdc", "Cdc"])

"Scalar DC branch parameters in Matpower format, to be replicated for each conductor"
const _branchdc_uniform_parameters = Set(["l", "c", "rateA", "rateB", "rateC"])

"Scalar DC converter parameters in Matpower format, to be replicated for each pole"
const _convdc_uniform_parameters = Set([
        "P_g", "Q_g", "rtf", "xtf", "tm", "bf", "rc", "xc", "Vmmax", "Vmmin", "Imax",
        "LossA", "LossB", "LossCrec", "LossCinv", "droop", "Pdcset", "Vdcset", "dVdcset",
        "Pacmax", "Pacmin", "Qacmax", "Qacmin",
        # Parameters not present in input files, but created by `check_conv_parameters`
        "Pacrated", "Qacrated"
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
        terminals = 3
        busdc["terminals"] = terminals
        # Voltage bounds: apply the same offset to each terminal
        for param in ["Vdcmin", "Vdcmax"]
            busdc[param] = (busdc[param] - 1.0) .+ [1.0, -1.0, 0.0]
        end
        # Voltage start value: apply the same magnitude to positive and negative terminals
        busdc["Vdc"] = busdc["Vdc"] .* [1.0, -1.0, 0.0]
        for param in _busdc_uniform_parameters
            busdc[param] = fill(busdc[param], terminals)
        end
    end
end

function _make_multiconductor_branchdc!(branchdc_dict::Dict{String,<:Any})
    for (b, branchdc) in branchdc_dict
        if branchdc["line_confi"] == 1 # monopolar (symmetric or asymmetric)
            conductors = 2
        elseif branchdc["line_confi"] == 2 # bipolar
            conductors = 3
        else
            _Memento.error(_LOGGER, "Unexpected \"line_confi\" value for DC branch $b: found $(branchdc["line_confi"]), expected 1 or 2.")
        end
        delete!(branchdc, "line_confi")
        branchdc["conductors"] = conductors
        branchdc["status"] = conductorsDC_status(branchdc) .* branchdc["status"]
        branchdc["r"] = [fill(branchdc["r"], conductors-1)..., branchdc["return_z"]]
        delete!(branchdc, "return_z")
        for param in _branchdc_uniform_parameters
            branchdc[param] = fill(branchdc[param], conductors)
        end
    end
end

function _make_multiconductor_convdc!(convdc_dict::Dict{String,<:Any})
    for (c, convdc) in convdc_dict
        if convdc["conv_confi"] == 1 # monopolar (symmetric or asymmetric)
            poles = 1
        elseif convdc["conv_confi"] == 2 # bipolar
            poles = 2
        else
            _Memento.error(_LOGGER, "Unexpected \"conv_confi\" value for DC converter $c: found $(convdc["conv_confi"]), expected 1 or 2.")
        end
        delete!(convdc, "conv_confi")
        convdc["poles"] = poles
        convdc["status"] = conductorsDC_status(convdc) .* convdc["status"]
        for param in _convdc_uniform_parameters
            convdc[param] = fill(convdc[param], poles)
        end
    end
end

"Generate vector of multi-conductor status states for `convdc` and `branchdc` components"
function conductorsDC_status(item_data::Dict{String,<:Any})
    poles = Vector{Int}()
    if haskey(item_data, "poles")
        if item_data["poles"] == 1
            append!(poles, first(_component_busdc_terminal_lookup[item_data["connect_at"]], 1))
        else
            append!(poles, 1:2)
        end
    elseif haskey(item_data, "conductors")
        if item_data["conductors"] == 2
            append!(poles, _component_busdc_terminal_lookup[item_data["connect_at"]])
        else
            append!(poles, 1:3)
        end
    end
    return [item_data[key] for key in _mc_status[poles]]
end
