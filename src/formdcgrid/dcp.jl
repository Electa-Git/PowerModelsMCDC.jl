
"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractDCPModel, n::Int, i, busdc, Vdcset, busdc_terminal_conv_poles)
    # not used
end

## Updated constraints ##
"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_conv_poles) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_conv_poles) - qd + bs*1^2
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    vm = 1

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][pole] for pole in bus_conv_poles[c]) for c in keys(bus_conv_poles)) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts) * vm^2)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""

function constraint_ohms_dc_branch(pm::_PM.AbstractDCPModel, n::Int, f_bus, t_bus, f_idx, t_idx, branch)
    i_dc = _PM.var(pm, n, :i_dcgrid)
    vmdc = _PM.var(pm, n, :vdcm)
    r = branch["r"]
    status = branch["status"]

    conductors = keys(status)
    busdc_terminal_arcsdc = _PM.ref(pm, n, :busdc_terminal_arcsdc)
    for cond in conductors
        for (l,i,j) in busdc_terminal_arcsdc[(f_bus, cond)]            
            if (l,i,j) == f_idx
                if r[cond] == 0
                    JuMP.@constraint(pm.model, i_dc[(l,i,j)][cond] + i_dc[(l,j,i)][cond] == 0)
                    JuMP.@constraint(pm.model, vmdc[i][cond] - vmdc[j][cond] == 0)
                else
                    g = 1 / r[cond]
                    JuMP.@constraint(pm.model, i_dc[(l,i,j)][cond] == g * (vmdc[i][cond] - vmdc[j][cond]))
                    JuMP.@constraint(pm.model, i_dc[(l,j,i)][cond] == g * (vmdc[j][cond] - vmdc[i][cond]))
                end
            end
        end
    end
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint_new(pm::_PM.AbstractDCPModel, n::Int, i, busdc, Vdcset, busdc_terminal_conv_poles)
    # not used
end