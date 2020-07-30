function variable_dcbranch_current(pm::_PM.AbstractPowerModel; kwargs...)
end

function comp_start_value(comp::Dict{String,<:Any}, key::String, conductor::Int, default)
    if haskey(comp, key)
        return comp[key][conductor]
    else
        return default
    end
end


function comp_start_value(comp::Dict{String,<:Any}, key::String, default)
    return _PMs.comp_start_value(comp, key, default)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vdcm = _PM.var(pm, nw)[:vdcm] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:ncnds], base_name="$(nw)_vdcm_$(i)",
    start = comp_start_value(_PMs.ref(pm, nw, :bus, i), "Vdc", c, 1.0)
    ) for i in _PMs.ids(pm, nw, :bus)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(vdcm[i],  busdc["Vdcmin"])
            JuMP.set_upper_bound(vdcm[i],  busdc["Vdcmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :vm, _PM.ids(pm, nw, :busdc), vdcm)
end


"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_mc_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)

    # cnds = _PM.conductor_ids(pm; nw=nw)
    # ncnds = length(cnds)
    # display(_PM.ref(pm, nw, :arcs_dcgrid))
    # display(_PM.ref(pm, nw, :branchdc, l)["conductors"])
        # ncnds = _PM.ref(pm, nw, :branchdc, l)["conductors"]
    p = _PM.var(pm, nw)[:p_dcgrid] = Dict((l,i,j) =>JuMP.@variable(pm.model,
        ncnds = _PM.ref(pm, nw, :branchdc, l)["conductors"],
        [c in 1:ncnds], base_name="$(nw)_pdcgrid_$((l,i,j))",
        start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", c, 0.0)
        )  for (l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)
    )
    display(p)

    # if bounded
    # for arc in _PM.ref(pm, nw, :arcs_dcgrid)
    #     l,i,j = arc
    #     JuMP.set_lower_bound(p[arc],0)
    #     JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"])
    # end
    # end
    # end
#
#     display(p)
# #
    report && _IM.sol_component_value_edge(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), p)
end




"""
Returns a total (shunt+series) power magnitude bound for the from and to side
of a branch. The total current rating also implies a current bound through the
upper bound on the voltage magnitude of the connected buses.
"""
function _calc_branch_power_max_frto(branch::Dict, bus_fr::Dict, bus_to::Dict)
    return _calc_branch_power_max(branch, bus_fr), _calc_branch_power_max(branch, bus_to)
end


#######################################################

function variable_dcbranch_current(pm::_PM.AbstractPowerModel; kwargs...)
end

"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vdcm = _PM.var(pm, nw)[:vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_vdcm",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(vdcm[i],  busdc["Vdcmin"])
            JuMP.set_upper_bound(vdcm[i],  busdc["Vdcmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :vm, _PM.ids(pm, nw, :busdc), vdcm)
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p = _PM.var(pm, nw)[:p_dcgrid] = JuMP.@variable(pm.model,
    [(l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_pdcgrid",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", 1.0)
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_dcgrid)
            l,i,j = arc
            JuMP.set_lower_bound(p[arc], -_PM.ref(pm, nw, :branchdc, l)["rateA"])
            JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"])
        end
    end

    report && _IM.sol_component_value_edge(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), p)
end
