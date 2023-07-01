"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractDCPModel, n::Int,  i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pconv_ac = _PM.var(pm, n, :pconv_ac)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    v = 1
    # display("constraint_kcl_shunt")
    # display(p[a] for a in bus_arcs)
    # total_cond=length(bus_convs_ac)
       JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c]) for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*v^2)
      # JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs)   == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*v^2)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractDCPModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p, total_cond)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid, t_idx)

    for c = 1: total_cond
        display(JuMP.@constraint(pm.model, p_dc_fr[c] + p_dc_to[c] == 0))
    end
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractDCPModel, n::Int,  i)
    # not used
end

function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractDCPModel; kwrags...)
    # not used nw::Int=_PM.nw_id_default
end

function constraint_dc_branch_current(pm::_PM.AbstractDCPModel, n::Int,  f_bus, f_idx, ccm_max, p)
# do nothing
end

