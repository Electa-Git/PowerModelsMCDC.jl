#LPAC
"""
Shunt constraint using linearized voltage magnitude difference phi

```
sum(p) + sum(pconv_grid_ac)  == sum(pg) - sum(pd) - sum(gs*(1.0 + 2*phi)
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractLPACModel, n::Int, i::Int, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
    phi = _PM.var(pm, n, :phi, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)

    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(sum(qconv_grid_ac[c][pole] for pole in bus_conv_poles[c]) for c in keys(bus_conv_poles)) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(1.0 + 2*phi))
    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][pole] for pole in bus_conv_poles[c]) for c in keys(bus_conv_poles)) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(1.0 + 2*phi))
end

"""
DC branch power flow using linearized voltage magnitude difference phi

```
p_dc_fr == p * g *  (phi_fr - phi_to)
p_dc_to == p * g *  (phi_to - phi_fr)
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractLPACModel, n::Int,  f_bus, t_bus, f_idx, t_idx, branch)
    i_dc = _PM.var(pm, n, :i_dcgrid)
    phi_dc = _PM.var(pm, n, :phi_vdcm)
    r = branch["r"]
    status = branch["status"]

    conductors = keys(status)
    busdc_terminal_arcsdc = _PM.ref(pm, n, :busdc_terminal_arcsdc)
    for cond in conductors
        for (l,i,j) in busdc_terminal_arcsdc[(f_bus, cond)]            
            if (l,i,j) == f_idx
                if r[cond] == 0
                    JuMP.@constraint(pm.model, i_dc[(l,i,j)][cond] + i_dc[(l,j,i)][cond] == 0)
                    JuMP.@constraint(pm.model, phi_dc[i][cond] - phi_dc[j][cond] == 0)
                else
                    g = 1 / r[cond]
                    #JuMP.@constraint(pm.model, i_dc[(l,i,j)][cond] == g * (phi_dc[i][cond] - phi_dc[j][cond]))
                    #JuMP.@constraint(pm.model, i_dc[(l,j,i)][cond] == g * (phi_dc[j][cond] - phi_dc[i][cond]))

                    # I'm just trying here
                    JuMP.@constraint(pm.model, i_dc[(l,i,j)][cond] == (phi_dc[i][cond] - phi_dc[j][cond]))
                    JuMP.@constraint(pm.model, i_dc[(l,j,i)][cond] == (phi_dc[j][cond] - phi_dc[i][cond]))
                end
            end
        end
    end
end



