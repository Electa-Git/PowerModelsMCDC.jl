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
const _conductorless = Set(["index", "bus_i", "bus_type", "status", "gen_status",
    "br_status", "gen_bus", "load_bus", "shunt_bus", "storage_bus", "f_bus", "t_bus",
    "transformer", "area", "zone", "base_kv", "energy", "energy_rating", "charge_rating",
    "discharge_rating", "charge_efficiency", "discharge_efficiency", "p_loss", "q_loss",
    "model", "ncost", "cost", "startup", "shutdown", "name", "source_id", "active_phases"])

"only dc side data"
const _DCdata=["busdc", "convdc", "branchdc"]

"feild names that should become multi-conductor matrix not arrays"
const _conductor_matrix = Set(["br_r", "br_x"])


function _make_multiconductor!(data::Dict{String,<:Any}, conductors::Real)
    if haskey(data, "conductors")
        Memento.warn(_LOGGER, "skipping network that is already multiconductor")
        return
    end

    data["conductors"] = conductors

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
