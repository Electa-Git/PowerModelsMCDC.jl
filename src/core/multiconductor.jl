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

        # Voltage bounds: apply the same offset to each terminal
        for param in ["Vdcmin", "Vdcmax"]
            offset = busdc[param] - 1.0
            busdc[param] = Dict{String,Float64}(
                "p" =>  1.0 + offset,
                "r" =>  0.0 + offset,
                "n" => -1.0 + offset
            )
        end

        # Voltage start value: apply the same magnitude to positive and negative terminals
        magnitude = busdc["Vdc"]
        busdc["Vdc"] = Dict{String,Float64}(
            "p" =>  magnitude,
            "r" =>        0.0,
            "n" => -magnitude
        )

        # Uniform parameters
        for param in _busdc_uniform_parameters
            uniform_value = busdc[param]
            busdc[param] = Dict{String,Float64}(
                "p" => uniform_value,
                "r" => uniform_value,
                "n" => uniform_value
            )
        end
    end
end

function _make_multiconductor_branchdc!(branchdc_dict::Dict{String,<:Any})
    for (b, branchdc) in branchdc_dict
        conductors = branchdc["conductors"]
        if conductors ∉ (2, 3)
            _Memento.error(_LOGGER, "Unexpected \"conductors\" value for DC branch $b: found $conductors, expected 2 or 3.")
        end
        delete!(branchdc, "conductors")

        # Status
        overall_status = branchdc["status"]
        branchdc["status"] = Dict{String,Int}()
        if conductors == 3 || (conductors==2 && branchdc["connect_at"] != 2)
            branchdc["status"]["p"] = overall_status * branchdc["status_p"]
        end
        if conductors == 3 || (conductors==2 && branchdc["connect_at"] != 0)
            branchdc["status"]["r"] = overall_status * branchdc["status_r"]
        end
        if conductors == 3 || (conductors==2 && branchdc["connect_at"] != 1)
            branchdc["status"]["n"] = overall_status * branchdc["status_n"]
        end
        delete!(branchdc, "status_p")
        delete!(branchdc, "status_r")
        delete!(branchdc, "status_n")
        delete!(branchdc, "connect_at")

        # Resistance
        resistance_active_conductor = branchdc["r"]
        branchdc["r"] = Dict{String,Float64}()
        if haskey(branchdc["status"], "p")
            branchdc["r"]["p"] = resistance_active_conductor
        end
        if haskey(branchdc["status"], "r")
            branchdc["r"]["r"] = branchdc["return_z"]
        end
        if haskey(branchdc["status"], "n")
            branchdc["r"]["n"] = resistance_active_conductor
        end
        delete!(branchdc, "return_z")

        # Uniform parameters
        for param in _branchdc_uniform_parameters
            branchdc[param] = Dict{String,Float64}(
                conductor => branchdc[param] for conductor in keys(branchdc["status"])
            )
        end
    end
end

function _make_multiconductor_convdc!(convdc_dict::Dict{String,<:Any})
    for (c, convdc) in convdc_dict
        poles = convdc["poles"]
        if poles ∉ (1,2)
            _Memento.error(_LOGGER, "Unexpected \"poles\" value for DC converter $c: found $poles, expected 1 or 2.")
        end
        delete!(convdc, "poles")

        # Status
        overall_status = convdc["status"]
        convdc["status"] = Dict{String,Int}()
        if poles == 2 || (poles==1 && convdc["connect_at"] == 1)
            convdc["status"]["p"] = overall_status * convdc["status_p"]
        end
        if poles == 1 && convdc["connect_at"] == 0
            convdc["status"]["r"] = overall_status * convdc["status_r"]
        end
        if poles == 2 || (poles==1 && convdc["connect_at"] == 2)
            convdc["status"]["n"] = overall_status * convdc["status_n"]
        end
        delete!(convdc, "status_p")
        delete!(convdc, "status_r")
        delete!(convdc, "status_n")
        delete!(convdc, "connect_at")

        # Uniform parameters
        for param in _convdc_uniform_parameters
            convdc[param] = Dict{String,Float64}(
                pole => convdc[param] for pole in keys(convdc["status"])
            )
        end
    end
end
