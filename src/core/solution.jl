"builds solution structure composed by both variables and fixed values based on multi-conductor status parameter"
function sol_component_value_status(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name::Symbol, comp_ids, conductors, variables, constant=0.0)

    data = Dict{Int, Any}()
    for i in comp_ids
        data[i] = [in(c, first(conductors[i])) ? variables[i][c] : constant for c in 1:last(conductors[i])]
    end  
    _PM.sol_component_value(pm, n, comp_name, field_name, comp_ids, data)
end

"builds solution structure composed by both edge variables and fixed values based on multi-conductor status parameter"
function sol_component_value_edge_status(pm::_PM.AbstractPowerModel, n::Int, comp_name::Symbol, field_name_fr::Symbol, field_name_to::Symbol, comp_ids_fr, comp_ids_to, conductors, variables, constant=0.0)

    data = Dict{Tuple{Int, Int, Int}, Any}()
    for (l, i, j) in comp_ids_fr
        data[(l, i, j)] = [in(c, first(conductors[(l, i, j)])) ? variables[(l, i, j)][c] : constant for c in 1:last(conductors[(l, i, j)])]
    end
    for (l, i, j) in comp_ids_to
        data[(l, i, j)] = [in(c, first(conductors[(l, i, j)])) ? variables[(l, i, j)][c] : constant for c in 1:last(conductors[(l, i, j)])]
    end
    _PM.sol_component_value_edge(pm, n, comp_name, field_name_fr, field_name_to, comp_ids_fr, comp_ids_to, data)
end
