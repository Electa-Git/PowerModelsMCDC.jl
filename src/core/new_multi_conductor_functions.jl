"removing predefined conductor"

"Transforms single-conductor network data into multi-conductor data"
function make_multiconductor_new!(data::Dict{String,<:Any})
    if InfrastructureModels.ismultinetwork(data)
        for (i,nw_data) in data["nw"]
            _make_multiconductor!(nw_data)
        end
    else
         _make_multiconductor!(data)
    end
end


"feild names that should not be multi-conductor values"
const _conductorless = Set(["basekVdc", "source_id", "busdc_i", "grid", "index",
"return_type", "status", "confi", "return_z", "fbusdc", "tbusdc","busac_i", "dVdcset", "Vdcset", "basekVac",
"type_dc", "filter", "reactor", "transformer", "type_dc", "P_g", "Q_g", "Vtar", "status", "islcc",
"Pdcset", "droop", "ground_type", "line_confi", "conv_confi", "ground_z", "type_dc"])
#Assumed: control modes and setpoints are not per conductor.

"only dc side data"
const _DCdata=["busdc", "convdc", "branchdc"]

"feild names that should become multi-conductor matrix not arrays"
const _conductor_matrix = Set(["br_r", "br_x", "rc", "xc", "rtf", "xtf", "bf"])


using LinearAlgebra
function _make_multiconductor_new!(data::Dict{String,<:Any})
    # if haskey(data, "conductors")
    #     Memento.warn(_LOGGER, "skipping network that is already multiconductor")
    #     return
    # end

    data["conductors_dc"] = true

    for (key, item) in data
     if key in _DCdata
         display(key)
        if isa(item, Dict{String,Any})
            for (item_id, item_data) in item
                if isa(item_data, Dict{String,Any})
                    item_ref_data = Dict{String,Any}()
                    conductors= conductorsDC_number(item_data)
                    item_data["conductors"]=conductors
                    for (param, value) in item_data
                        if param in _conductorless
                            item_ref_data[param] = value
                        else
                            # if param in _conductor_matrix
                            #     item_ref_data[param] = LinearAlgebra.diagm(0=>fill(value, conductors))
                            # else
                                item_ref_data[param] = fill(value, conductors)
                            # end
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
             if item_data["conv_confi"]== 1 #monopolar coverter
                 conductors= 1
             else conductors= 2
             end
         elseif haskey(item_data, "confi")
             if item_data["line_confi"]== 1 #monopolar/symmetrical dc line
                conductors= 2
            else conductors= 3
            end
        else
            conductors= 3
        end
        println("pass")
        return conductors
end