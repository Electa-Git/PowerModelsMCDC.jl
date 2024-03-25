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
        conductors = branchdc["conductors"]
        if conductors ∉ (2, 3)
            _Memento.error(_LOGGER, "Unexpected \"conductors\" value for DC branch $b: found $conductors, expected 2 or 3.")
        end
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
        poles = convdc["poles"]
        if poles ∉ (1,2)
            _Memento.error(_LOGGER, "Unexpected \"poles\" value for DC converter $c: found $poles, expected 1 or 2.")
        end
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
