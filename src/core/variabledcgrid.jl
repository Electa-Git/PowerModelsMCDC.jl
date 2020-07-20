
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

function variable_mcdcgrid_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report::Bool=true)
    cnds = _PMs.conductor_ids(pm; nw=nw)
    ncnds = length(cnds)

    phivdcm = _PM.var(pm, nw)[:phi_vdcm] = Dict(i => JuMP.@variable(pm.model,
    [c in 1:ncnds], base_name="$(nw)_phi_vdcm_$(i)",
    start = comp_start_value(_PMs.ref(pm, nw, :bus, i), "Vdc", c, 1.0)
    ) for i in _PM.ids(pm, nw, :bus)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(phivdcm[i],  busdc["Vdcmin"] - 1)
            JuMP.set_upper_bound(phivdcm[i],  busdc["Vdcmax"] - 1)
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :phivdcm, _PM.ids(pm, nw, :busdc), phivdcm)

end

# function variable_mc_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
#     cnds = _PMs.conductor_ids(pm; nw=nw)
#     ncnds = length(cnds)
#
#     vm = _PMs.var(pm, nw)[:vm] = Dict(i => JuMP.@variable(pm.model,
#             [c in 1:ncnds], base_name="$(nw)_vm_$(i)",
#             start = comp_start_value(_PMs.ref(pm, nw, :bus, i), "vm_start", c, 1.0)
#         ) for i in _PMs.ids(pm, nw, :bus)
#     )
#
#     if bounded
#         for (i,bus) in _PMs.ref(pm, nw, :bus)
#             if haskey(bus, "vmin")
#                 set_lower_bound.(vm[i], bus["vmin"])
#             end
#             if haskey(bus, "vmax")
#                 set_upper_bound.(vm[i], bus["vmax"])
#             end
#         end
#     end
#
#     report && _PM.sol_component_value(pm, nw, :bus, :vm, _PMs.ids(pm, nw, :bus), vm)
# end




"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_mc_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    for (l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)
    # cnds = _PM.conductor_ids(pm; nw=nw)

    ncnds = length(cnds)
    p = _PM.var(pm, nw)[:p_dcgrid] = Dict((l,i,j) =>JuMP.@variable(pm.model,
        [c in 1:ncnds], base_name="$(nw)_pdcgrid_$((l,i,j))",
        start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", c, 0.0)
        )
    )
    display(p)
    display(ncnds)
    if bounded
    for arc in _PM.ref(pm, nw, :arcs_dcgrid)
        l,i,j = arc
        JuMP.set_lower_bound(p[arc],0)
        JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"])
    end
end

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

function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report::Bool=true)
    phivdcm = _PM.var(pm, nw)[:phi_vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_phi_vdcm",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc")
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(phivdcm[i],  busdc["Vdcmin"] - 1)
            JuMP.set_upper_bound(phivdcm[i],  busdc["Vdcmax"] - 1)
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :phivdcm, _PM.ids(pm, nw, :busdc), phivdcm)

end
"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wdc = _PM.var(pm, nw)[:wdc] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_wdc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )
    wdcr = _PM.var(pm, nw)[:wdcr] = JuMP.@variable(pm.model,
    [(i,j) in _PM.ids(pm, nw, :buspairsdc)], base_name="$(nw)_wdcr",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(wdc[i],  busdc["Vdcmin"]^2)
            JuMP.set_upper_bound(wdc[i],  busdc["Vdcmax"]^2)
        end
        for (bp, buspairdc) in _PM.ref(pm, nw, :buspairsdc)
            JuMP.set_lower_bound(wdcr[bp],  0)
            JuMP.set_upper_bound(wdcr[bp],  buspairdc["vm_fr_max"] * buspairdc["vm_to_max"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :wdc, _PM.ids(pm, nw, :busdc), wdc)
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
