"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::_PM.AbstractDCPModel, n::Int, i::Int, a, b, c, plmax, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond] #cond defined over conveter
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[cond]

    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac / v # can actually be negative, not a very nice model...
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a + b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a - b * cm_conv_ac)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg <= plmax)
end

function constraint_converter_dc_current(pm::_PM.AbstractDCPModel, n::Int, i::Int)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)
    vdcm = 1.0

    dc_bus = _PM.ref(pm, n, :convdc, i)["busdc_i"]
    conv_cond = _PM.ref(pm, n, :convdc, i)["conductors"]
    bus_convs_dc_cond = _PM.ref(pm, n, :bus_convs_dc_cond)

    total_cond = _PM.ref(pm, n, :busdc, i)["conductors"]
    for k in 1:total_cond
        for (c, d) in bus_convs_dc_cond[(dc_bus, k)]
            if k == 1
                vdcm = 1 #metallic return volatage is taken 0
            elseif k == 2
                vdcm = -1
            elseif k == 3
                vdcm = -0
            end

            if c == i
                JuMP.@constraint(pm.model, pconv_dc[c][d] == iconv_dc[c][d] * vdcm)
            end
        end
    end

    # neutral is always connected at bus conductor "3"
    for g in 1:conv_cond
        vdcm = 0
        JuMP.@constraint(pm.model, pconv_dcg[i][g] == iconv_dcg[i][g] * vdcm)
        JuMP.@constraint(pm.model, iconv_dc[i][g] + iconv_dcg[i][g] == 0)
    end
    JuMP.@constraint(pm.model, sum(iconv_dc[i][c] for c in 1:conv_cond+1) == 0)

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
        # display("reactor is present")
        bc = imag(1 / (im * xc))
        v = 1 # pu, assumption DC approximation
        JuMP.@constraint(pm.model, ppr_fr == -bc * (v^2) * (vaf - vac))
        JuMP.@constraint(pm.model, ppr_to == -bc * (v^2) * (vac - vaf))
    else
        # display("reactor is NOT there")
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

    # _PM.con(pm, n, :conv_kcl_p)[i] = JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
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
"""
Converter grounding constraint
```
```
"""
function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractDCPModel, n::Int)

    for i in _PM.ids(pm, n, :busdc)
        vdc = _PM.var(pm, n, :vdcm, i)
        JuMP.@constraint(pm.model, vdc[3] == 0)
    end
end
