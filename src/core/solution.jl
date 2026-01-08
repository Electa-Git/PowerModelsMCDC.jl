"builds solution structure composed by both variables and fixed values based on multi-conductor status parameter"



### Updated functions 

function sol_component_value_status(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, conductors, variables)

    data = Dict{Int, Any}()
    for i in comp_ids
        data[i] = Dict(c => variables[i][c] for c in conductors[i])
    end  
    _PM.sol_component_value(pm, n, comp_name, field_name, comp_ids, data)
end

function sol_component_value_status_grounding(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, grounded_convs, variables)

    data = Dict{Int, Any}()
    for i in comp_ids
        data[i] = Dict(c => variables[i] for c in keys(grounded_convs[i]))
    end 
    

    _PM.sol_component_value(pm, n, comp_name, field_name, comp_ids, data)
end


"builds solution structure composed by both edge variables and fixed values based on multi-conductor status parameter"
function sol_component_value_edge_status(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, conductors, variables)

    data = Dict{Tuple{Int, Int, Int}, Any}()
    for (l, i, j) in comp_ids_fr
        data[(l, i, j)] = Dict(c => variables[(l, i, j)][c] for c in conductors[l])
    end

    for (l, i, j) in comp_ids_to
        data[(l, i, j)] = Dict(c => variables[(l, i, j)][c] for c in conductors[l])
    end

    _PM.sol_component_value_edge(pm, n, comp_name, field_name_fr, field_name_to, comp_ids_fr, comp_ids_to, data)
end

function sol_component_value_edge_status_sw(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, variables)

    data = Dict{Tuple{Int, Int, Int},Any}()
    for (l, i, j, cond) in comp_ids_fr
        data[(l, i, j)] = variables[(l, i, j, cond)]
    end

    for (l, i, j, cond) in comp_ids_to
        data[(l, i, j)] = variables[(l, i, j, cond)]
    end

    _PM.sol_component_value_edge(pm, n, comp_name, field_name_fr, field_name_to, comp_ids_fr, comp_ids_to, data)
end