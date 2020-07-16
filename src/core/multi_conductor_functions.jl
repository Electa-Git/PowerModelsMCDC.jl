"Transforms single-conductor network data into multi-conductor data"
function make_multiconductor!(data::Dict{String,<:Any}, conductors::Int)
    if InfrastructureModels.ismultinetwork(data)
        for (i,nw_data) in data["nw"]
            _make_multiconductor!(nw_data, conductors)
        end
    else
         _make_multiconductor!(data, conductors)
    end
end


"feild names that should not be multi-conductor values"
const _conductorless = Set(["basekVdc", "source_id", "busdc_i", "grid", "index",
"return_type", "status", "confi", "return_z", "fbusdc", "tbusdc","busac_i", "dVdcset", "Vdcset", "basekVac",
"type_dc", "filter", "reactor", "transformer", "type_dc", "P_g", "Q_g", "Vtar", "status", "islcc",
"Pdcset", "droop", "ground_type", "Confi", "ground_z", "type_dc"])
#Assumed: control modes and setpoints are not per conductor.

"only dc side data"
const _DCdata=["busdc", "convdc", "branchdc"]

"feild names that should become multi-conductor matrix not arrays"
const _conductor_matrix = Set(["br_r", "br_x", "rc", "xc", "rtf", "xtf", "bf"])


using LinearAlgebra
function _make_multiconductor!(data::Dict{String,<:Any}, conductors::Real)
    if haskey(data, "conductors")
        Memento.warn(_LOGGER, "skipping network that is already multiconductor")
        return
    end

    data["conductors_dc"] = conductors

    for (key, item) in data
     if key in _DCdata
        if isa(item, Dict{String,Any})
            for (item_id, item_data) in item
                if isa(item_data, Dict{String,Any})
                    item_ref_data = Dict{String,Any}()
                    for (param, value) in item_data
                        if param in _conductorless
                            item_ref_data[param] = value
                        else
                            if param in _conductor_matrix
                                item_ref_data[param] = LinearAlgebra.diagm(0=>fill(value, conductors))
                            else
                                item_ref_data[param] = fill(value, conductors)
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
