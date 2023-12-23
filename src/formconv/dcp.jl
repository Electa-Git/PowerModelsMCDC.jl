"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::_PM.AbstractDCPModel, n::Int, i::Int, a, b, c, plmax, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[cond]

    v = 1.0 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac / v # can actually be negative, not a very nice model...
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a + b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a - b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg <= plmax)
end

function constraint_converter_dc_current(pm::_PM.AbstractDCPModel, n::Int, i::Int, busdc::Int, vdcm, bus_cond_convs_dc_cond)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)
    iconv_dc = _PM.var(pm, n, :iconv_dc, i)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg, i)

    for (bus_cond, convs) in bus_cond_convs_dc_cond
        for (conv, conv_cond) in convs
            if conv == i
                JuMP.@constraint(pm.model, pconv_dc[conv_cond] == iconv_dc[conv_cond] * vdcm[bus_cond])
            end
        end
    end
    for c in first(axes(iconv_dcg))
        vdcm = -0.0
        JuMP.@constraint(pm.model, pconv_dcg[c] == iconv_dcg[c] * vdcm)
        JuMP.@constraint(pm.model, iconv_dc[c] + iconv_dcg[c] == 0)
    end
    JuMP.@constraint(pm.model, sum(iconv_dc) == 0)
end

"""
Converter grounding constraint
```
```
"""
function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractDCPModel, n::Int, bus_convs_grounding_shunt, r_earth)
    pconv_dcg_shunt = _PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    vref = -0.0

    for i in _PM.ids(pm, n, :busdc)
        vdcm = _PM.var(pm, n, :vdcm, i)
        for c in bus_convs_grounding_shunt[(i, 3)]
            r = _PM.ref(pm, n, :convdc, c)["ground_z"] + r_earth # The r_earth is kept to indicate the inclusion of earth resistance, if required in case of ground return
            if r == 0 #solid grounding
                JuMP.@constraint(pm.model, vdcm[3] == 0)
            else
                JuMP.@constraint(pm.model, pconv_dcg_shunt[c] == (1 / r) * vdcm[3] * vref)
                JuMP.@constraint(pm.model, iconv_dcg_shunt[c] == (1 / r) * vdcm[3])
            end
        end
    end
end

"""
Converter transformer constraints

```
p_tf_fr == -btf*(v^2)/tm*(va-vaf)
p_tf_to == -btf*(v^2)/tm*(vaf-va)
```
"""
function constraint_conv_transformer(pm::_PM.AbstractDCPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, cond)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]

    vaf = _PM.var(pm, n, :vaf, i)[cond]
    va = _PM.var(pm, n, :va, acbus)

    if transformer
        btf = imag(1 / (im * xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        JuMP.@constraint(pm.model, ptf_fr == -btf * (v^2) / tm * (va - vaf))
        JuMP.@constraint(pm.model, ptf_to == -btf * (v^2) / tm * (vaf - va))
    else
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
    end
end
"""
Converter reactor constraints

```
p_pr_fr == -bc*(v^2)*(vaf-vac)
pconv_ac == -bc*(v^2)*(vac-vaf)
```
"""
function constraint_conv_reactor(pm::_PM.AbstractDCPModel, n::Int, i::Int, rc, xc, reactor, cond)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    ppr_to = -pconv_ac
    vaf = _PM.var(pm, n, :vaf, i)[cond]
    vac = _PM.var(pm, n, :vac, i)[cond]
    if reactor
        bc = imag(1 / (im * xc))
        v = 1 # pu, assumption DC approximation
        JuMP.@constraint(pm.model, ppr_fr == -bc * (v^2) * (vaf - vac))
        JuMP.@constraint(pm.model, ppr_to == -bc * (v^2) * (vac - vaf))
    else
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
    end
end
"""
Converter filter constraints (no active power losses)
```
p_pr_fr + p_tf_to == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractDCPModel, n::Int, i::Int, bv, filter, cond)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]

    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0)
end
"""
Converter current constraint (not applicable)
```
```
"""
function constraint_converter_current(pm::_PM.AbstractDCPModel, n::Int, i::Int, Umax, Imax, cond)
    # not used
end

"""
Converter reactive power setpoint constraint (PF only, not applicable)
```
```
"""
function constraint_reactive_conv_setpoint(pm::_PM.AbstractDCPModel, n::Int, i, qconv)
end
"""
Converter firing angle constraint (not applicable)
```
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractDCPModel, n::Int, i::Int, S, P1, Q1, P2, Q2)
end
