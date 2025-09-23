"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_conv_poles) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_conv_poles) - qd + bs*v^2
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
    vm = _PM.var(pm, n, :vm, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)

    JuMP.@NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][d] for d in first(axes(_PM.var(pm, n, :pconv_tf_fr, c)))) for c in bus_conv_poles) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts) * vm^2)
    JuMP.@NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(sum(qconv_grid_ac[c][d] for d in first(axes(_PM.var(pm, n, :qconv_tf_fr, c)))) for c in bus_conv_poles) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts) * vm^2)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractACPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p, total_cond)
    i_dc_fr = _PM.var(pm, n, :i_dcgrid, f_idx)
    i_dc_to = _PM.var(pm, n, :i_dcgrid, t_idx)
    vmdc_fr = _PM.var(pm, n, :vdcm, f_bus)
    vmdc_to = _PM.var(pm, n, :vdcm, t_bus)

    busdc_terminal_arcsdc = _PM.ref(pm, n, :busdc_terminal_arcsdc)

    for k = 1:3
        for (line, d) in busdc_terminal_arcsdc[(f_bus, k)]
            if line == f_idx
                if r[d] == 0
                    JuMP.@constraint(pm.model, i_dc_fr[d] + i_dc_to[d] == 0)
                    JuMP.@constraint(pm.model, vmdc_fr[k] - vmdc_to[k] == 0)
                else
                    g = 1 / r[d]
                    JuMP.@constraint(pm.model, i_dc_fr[d] == g * (vmdc_fr[k] - vmdc_to[k]))
                    JuMP.@constraint(pm.model, i_dc_to[d] == g * (vmdc_to[k] - vmdc_fr[k]))
                end
            end
        end
    end
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractACPModel, n::Int, i, busdc, Vdcset, busdc_terminal_conv_poles)
    vdcm = _PM.var(pm, n, :vdcm, busdc)

    for bus_cond in 1:2
        for (conv, conv_cond) in busdc_terminal_conv_poles[(busdc, bus_cond)]
            if conv == i
                JuMP.@constraint(pm.model, vdcm[bus_cond] == Vdcset[conv_cond])
            end
        end
    end
end

#################### New constraints ####################

function constraint_kcl_shunt_new(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
    vm = _PM.var(pm, n, :vm, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)

    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(sum(qconv_grid_ac[c][pole] for pole in bus_conv_poles[c]) for c in keys(bus_conv_poles)) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts) * vm^2)
    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][pole] for pole in bus_conv_poles[c]) for c in keys(bus_conv_poles)) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts) * vm^2)
end

function constraint_ohms_dc_branch_new(pm::_PM.AbstractPowerModel, n::Int, f_bus, t_bus, f_idx, t_idx, branch)
    i_dc = _PM.var(pm, n, :i_dcgrid)
    #i_dc_to = _PM.var(pm, n, :i_dcgrid)
    vmdc = _PM.var(pm, n, :vdcm)
    #vmdc_to = _PM.var(pm, n, :vdcm)
    r = branch["r"]
    status = branch["status"]

    conductors = keys(status)
    busdc_terminal_arcsdc = _PM.ref(pm, n, :busdc_terminal_arcsdc)
    count_ = 0
    for cond in conductors
        for (l,i,j) in busdc_terminal_arcsdc[(f_bus, cond)]            
            if (l,i,j) == f_idx
                println("Let's go with $((l,i,j)) and cond $cond, f_idx is $f_idx")
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