"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    vm = 1
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    vm = 1
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    (JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][d] for d in 1:length(_PM.var(pm, n, :pconv_tf_fr, c))) for c in bus_convs_ac) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts) * vm^2))
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""

function constraint_ohms_dc_branch(pm::_PM.AbstractDCPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p, total_cond)
    i_dc_fr = _PM.var(pm, n, :i_dcgrid, f_idx)
    i_dc_to = _PM.var(pm, n, :i_dcgrid, t_idx)
    vmdc_fr = _PM.var(pm, n, :vdcm, f_bus)
    vmdc_to = _PM.var(pm, n, :vdcm, t_bus)
    bus_arcs_dcgrid_cond = _PM.ref(pm, n, :bus_arcs_dcgrid_cond)

    for k = 1:3
        # display("$k")
        for (line, d) in bus_arcs_dcgrid_cond[(f_bus, k)]
            if line == f_idx
                # if r[d] == 0
                JuMP.@constraint(pm.model, i_dc_fr[d] + i_dc_to[d] == 0)
                JuMP.@constraint(pm.model, vmdc_fr[k] - vmdc_to[k] == 0)
                # else
                #          g = 1 / r[d]
                #          # display("$line, $d")
                #         (JuMP.@NLconstraint(pm.model, i_dc_fr[d] ==  g * (vmdc_fr[k] - vmdc_to[k])))
                #         (JuMP.@NLconstraint(pm.model, i_dc_to[d] ==  g * (vmdc_to[k] - vmdc_fr[k])))
                #  end
            end
        end
    end
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractDCPModel, n::Int, i)
    # not used
end

