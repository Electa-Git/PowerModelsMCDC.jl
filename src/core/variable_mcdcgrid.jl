
function comp_start_value(comp::Dict{String,<:Any}, key::String, conductor::Vector{Int}, default)
    return [comp_start_value(comp, key, c, default) for c in conductor]
end

function comp_start_value(comp::Dict{String,<:Any}, key::String, conductor::Int, default)
    if haskey(comp, key)
        return comp[key][conductor]
    else
        return default
    end
end

function comp_start_value(comp::Dict{String,<:Any}, key::String, default)
    return _PM.comp_start_value(comp, key, default)
end

"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_mcdcgrid_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:vdcm] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :busdc)[i]["conductors"]], base_name = "$(nw)_vdcm_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", c, 1.0)
    ) for i in _PM.ids(pm, nw, :busdc)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound.(vars[i], busdc["Vdcmin"])
            JuMP.set_upper_bound.(vars[i], busdc["Vdcmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :busdc, :vm, _PM.ids(pm, nw, :busdc), vars)
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_mc_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :arcs_dcgrid_cond)
    vars = _PM.var(pm, nw)[:p_dcgrid] = Dict((l, i, j) => JuMP.@variable(pm.model,
        [first(conductors[(l, i, j)])], base_name = "$(nw)_pdcgrid_$((l,i,j))",
    ) for (l, i, j) in _PM.ref(pm, nw, :arcs_dcgrid)
    )
    
    for arc in _PM.ref(pm, nw, :arcs_dcgrid)
        JuMP.set_start_value.(vars[arc], comp_start_value(_PM.ref(pm, nw, :branchdc, first(arc)), "p_start", first(conductors[arc]), 0.0))
        if bounded
            JuMP.set_lower_bound.(vars[arc], -_PM.ref(pm, nw, :branchdc, first(arc))["rateA"][first(conductors[arc])])
            JuMP.set_upper_bound.(vars[arc], _PM.ref(pm, nw, :branchdc, first(arc))["rateA"][first(conductors[arc])])
        end
    end

    report && sol_component_value_edge_status(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), conductors, vars)
end

"variable: `i_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_mc_dcbranch_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :arcs_dcgrid_cond)
    vars = _PM.var(pm, nw)[:i_dcgrid] = Dict((l, i, j) => JuMP.@variable(pm.model,
        [first(conductors[(l, i, j)])], base_name = "$(nw)_idcgrid_$((l,i,j))",
    ) for (l, i, j) in _PM.ref(pm, nw, :arcs_dcgrid)
    )
    # TODO: more detailed analysis of starting value and bounds
    for arc in _PM.ref(pm, nw, :arcs_dcgrid)
        JuMP.set_start_value.(vars[arc], comp_start_value(_PM.ref(pm, nw, :branchdc, first(arc)), "i_start", first(conductors[arc]), 0.0))
        if bounded
            JuMP.set_lower_bound.(vars[arc], -_PM.ref(pm, nw, :branchdc, first(arc))["rateA"][first(conductors[arc])])
            JuMP.set_upper_bound.(vars[arc], _PM.ref(pm, nw, :branchdc, first(arc))["rateA"][first(conductors[arc])])
        end
    end

    report && sol_component_value_edge_status(pm, nw, :branchdc, :i_from, :i_to, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), conductors, vars)
end

"""
Returns a total (shunt+series) power magnitude bound for the from and to side
of a branch. The total current rating also implies a current bound through the
upper bound on the voltage magnitude of the connected buses.
"""
function _calc_branch_power_max_frto(branch::Dict, bus_fr::Dict, bus_to::Dict)
    return _calc_branch_power_max(branch, bus_fr), _calc_branch_power_max(branch, bus_to)
end
