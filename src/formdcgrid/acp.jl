"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    vm = _PM.var(pm, n, :vm, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)

    JuMP.@NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(sum(pconv_grid_ac[c][d] for d in 1:length(_PM.var(pm, n, :pconv_tf_fr, c))) for c in bus_convs_ac) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts) * vm^2)
    JuMP.@NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(sum(qconv_grid_ac[c][d] for d in 1:length(_PM.var(pm, n, :qconv_tf_fr, c))) for c in bus_convs_ac) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts) * vm^2)
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

    bus_arcs_dcgrid_cond = _PM.ref(pm, n, :bus_arcs_dcgrid_cond)

    for k = 1:3
        for (line, d) in bus_arcs_dcgrid_cond[(f_bus, k)]
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
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractACPModel, n::Int, i)

    conv = _PM.ref(pm, n, :convdc, i)
    dc_bus = _PM.ref(pm, n, :convdc, i)["busdc_i"]
    v = _PM.var(pm, n, :vdcm, dc_bus)

    bus_convs_dc_cond = _PM.ref(pm, n, :bus_convs_dc_cond)
    for k in 1:2
        for (c, d) in bus_convs_dc_cond[(dc_bus, k)]
            if c == i
                # display("dc voltage constraint for conv $i")
                (JuMP.@constraint(pm.model, v[k]-v[3] == conv["Vdcset"][d]))
            end
        end
    end

end

function constraint_ac_voltage_setpoint(pm::_PM.AbstractACPModel, nw ::Int, i ::Int )
    ac_bus = _PM.ref(pm, nw, :convdc, i)["busac_i"]
    # @assert bus["bus_type"] == 2
    _PM.constraint_voltage_magnitude_setpoint(pm, ac_bus)
end

function constraint_dc_droop_control(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc_i, vref_dc, pref, k_droop, cond)
    # pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    pgrid = _PM.var(pm, n, :pconv_tf_fr, i)
    # vdc = _PM.var(pm, n, :vdcm, busdc_i)

    conv = _PM.ref(pm, n, :convdc, i)
    dc_bus = _PM.ref(pm, n, :convdc, i)["busdc_i"]
    v = _PM.var(pm, n, :vdcm, dc_bus)

    bus_convs_dc_cond = _PM.ref(pm, n, :bus_convs_dc_cond)
    for k in 1:2
        for (c, d) in bus_convs_dc_cond[(dc_bus, k)]
            if c == i
                # (JuMP.@constraint(pm.model, v[k] == conv["Vdcset"][d]))
                display("dc droop constraint for conv $i")
                # @show pconv_dc pref_dc[1] k_droop[1] vref_dc[1]
                # (JuMP.@constraint(pm.model, -pconv_dc[cond] == pref[cond] - sign(pref[cond])*sign(vref_dc[cond])* 1 / k_droop[cond] * (v[k]-v[3] - vref_dc[cond])) )
                # display(JuMP.@constraint(pm.model, pgrid[cond] == -pref[cond] - sign(pref[cond])*sign(vref_dc[cond])* 1 / k_droop[cond] * (v[k]-v[3] - vref_dc[cond])) )
                display(JuMP.@constraint(pm.model, pgrid[cond] == -pref[cond] - sign(vref_dc[cond])* 1 / k_droop[cond] * (v[k]-v[3] - vref_dc[cond])) )
                # @show pgrid[cond], pref[cond], v[k], v[3], vref_dc[cond], sign(pref[cond]),sign(vref_dc[cond]) 
                
             end
        end
    end
end

function constraint_ac_droop_control(pm::_PM.AbstractACPModel, n::Int, i::Int, busac_i, vref_ac, qref, k_droop_ac, cond)
    qgrid = _PM.var(pm, n, :qconv_tf_fr, i)[cond]
    vac = _PM.var(pm, n, :vm, busac_i)
    # @show qconv, qref[cond], k_droop_ac[cond], vac, vref_ac
    display("ac droop constraint for conv $i")
    display(JuMP.@constraint(pm.model, -qgrid == qref[cond] - 1 / k_droop_ac[cond] * (vac - vref_ac[cond])))
end