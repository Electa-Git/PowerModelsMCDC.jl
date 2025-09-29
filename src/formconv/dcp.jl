
## Updated constraints
"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::_PM.AbstractDCPModel, n::Int, i::Int, conv, pole)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole]
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[pole]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[pole]

    a = conv["LossA"][pole]
    b = conv["LossB"][pole]
    c = conv["LossCinv"][pole]

    plmax = conv["LossA"][pole] + conv["LossB"][pole] * conv["Pacrated"][pole] + conv["LossCinv"][pole] * (conv["Pacrated"][pole])^2
    v = 1.0 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac / v # can actually be negative, not a very nice model...
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a + b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a - b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg <= plmax)
end



function constraint_converter_dc_current(pm::_PM.AbstractDCPModel, n::Int, i::Int, busdc::Int, terminals, poles, busdc_terminal_conv_poles)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)
    

    for terminal in terminals
        for (conv_id,pole) in busdc_terminal_conv_poles[busdc][terminal]
            if terminal == "r"
                vdcm = 0.0
                JuMP.@constraint(pm.model, pconv_dc[conv_id][terminal] == iconv_dc[conv_id][terminal] * vdcm)
            elseif terminal == "p"
                vdcm = 1.0
                JuMP.@constraint(pm.model, pconv_dc[conv_id][pole] == iconv_dc[conv_id][pole] * vdcm)
            elseif terminal == "n"
                vdcm = - 1.0
                JuMP.@constraint(pm.model, pconv_dc[conv_id][pole] == iconv_dc[conv_id][pole] * vdcm)
            end
        end
    end
    for pole in poles
        vdcm = 0.0
        JuMP.@constraint(pm.model, pconv_dcg[i][pole] == iconv_dcg[i][pole] * vdcm)
        JuMP.@constraint(pm.model, iconv_dc[i][pole] + iconv_dcg[i][pole] == 0)
    end

    JuMP.@constraint(pm.model, sum(iconv_dc[i]) == 0)
end

"""
Converter grounding constraint
```
```
"""
function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractDCPModel, n::Int, busdc_grounded_convs, r_earth)
    pconv_dcg_shunt = _PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    vref = -0.0

    for i in _PM.ids(pm, n, :busdc)
        vdcm = _PM.var(pm, n, :vdcm, i)
        for c in busdc_grounded_convs[i]
            r = _PM.ref(pm, n, :convdc, c)["ground_z"] + r_earth # The r_earth is kept to indicate the inclusion of earth resistance, if required in case of ground return
            if r == 0 #solid grounding
                JuMP.@constraint(pm.model, vdcm["r"] == 0)
            else
                JuMP.@constraint(pm.model, pconv_dcg_shunt[c] == (1 / r) * vdcm["r"] * vref)
                JuMP.@constraint(pm.model, iconv_dcg_shunt[c] == (1 / r) * vdcm["r"])
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
function constraint_conv_transformer(pm::_PM.AbstractDCPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, pole)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]

    vaf = _PM.var(pm, n, :vaf, i)[pole]
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
function constraint_conv_reactor(pm::_PM.AbstractDCPModel, n::Int, i::Int, rc, xc, reactor, pole)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole]
    ppr_to = -pconv_ac
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    vac = _PM.var(pm, n, :vac, i)[pole]
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
function constraint_conv_filter(pm::_PM.AbstractDCPModel, n::Int, i::Int, bv, filter, pole)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]

    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0)
end
"""
Converter current constraint (not applicable)
```
```
"""
function constraint_converter_current(pm::_PM.AbstractDCPModel, n::Int, i::Int, pole)
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