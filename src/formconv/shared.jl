"""
Creates lossy converter model between AC and DC grid
```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses(pm::_PM.AbstractPowerModel, n::Int, i::Int, a, b, c, plmax, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond] #cond defined over conveter
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[cond]
    iconv = _PM.var(pm, n, :iconv_ac, i)[cond]

    JuMP.@NLconstraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == a + b * iconv + c * iconv^2)
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, n::Int, i::Int, busdc::Int, vdcm, bus_cond_convs_dc_cond)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)
    iconv_dc = _PM.var(pm, n, :iconv_dc, i)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg, i)
    vdcm = _PM.var(pm, n, :vdcm, busdc)

    for (bus_cond, convs) in bus_cond_convs_dc_cond
        for (conv, conv_cond) in convs
            if conv == i
                JuMP.@NLconstraint(pm.model, pconv_dc[conv_cond] == iconv_dc[conv_cond] * vdcm[bus_cond])
            end
        end
    end
    for c in first(axes(iconv_dcg))
        JuMP.@NLconstraint(pm.model, pconv_dcg[c] == iconv_dcg[c] * vdcm[3]) # neutral is always connected at bus conductor "3"
        JuMP.@constraint(pm.model, iconv_dc[c] + iconv_dcg[c] == 0)
    end
    JuMP.@constraint(pm.model, sum(iconv_dc) == 0)
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractPowerModel, n::Int, bus_convs_grounding_shunt, r_earth)
    pconv_dcg_shunt = _PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)

    for i in _PM.ids(pm, n, :busdc)
        vdcm = _PM.var(pm, n, :vdcm, i)
        for c in bus_convs_grounding_shunt[(i, 3)]
            r = _PM.ref(pm, n, :convdc, c)["ground_z"] + r_earth # The r_earth is kept to indicate the inclusion of earth resistance, if required in case of ground return
            if r == 0 #solid grounding
                JuMP.@constraint(pm.model, vdcm[3] == 0)
            else
                JuMP.@NLconstraint(pm.model, pconv_dcg_shunt[c] == (1 / r) * vdcm[3]^2)
                JuMP.@constraint(pm.model, iconv_dcg_shunt[c] == (1 / r) * vdcm[3])
            end
        end
    end
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, n::Int, i::Int, S, P1, Q1, P2, Q2, cond)
    p = _PM.var(pm, n, :pconv_ac, i)[cond]
    q = _PM.var(pm, n, :qconv_ac, i)[cond]
    phi = _PM.var(pm, n, :phiconv, i)[cond]

    JuMP.@NLconstraint(pm.model, p == cos(phi) * S)
    JuMP.@NLconstraint(pm.model, q == sin(phi) * S)
end
