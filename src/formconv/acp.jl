#################### Updated constraints ####################
"""
Creates lossy converter model between AC and DC grid
```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses(pm::_PM.AbstractACPModel, n::Int, i::Int, conv, pole)
    
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole] 
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[pole]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[pole]
    iconv = _PM.var(pm, n, :iconv_ac, i)[pole]

    a = conv["LossA"][pole]
    b = conv["LossB"][pole]
    c = conv["LossCinv"][pole]

    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == a + b * iconv + c * iconv^2)
end

"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::_PM.AbstractACPModel, n::Int, i::Int, pole)
    vmc = _PM.var(pm, n, :vmc, i)[pole]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole]
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)[pole]
    iconv = _PM.var(pm, n, :iconv_ac, i)[pole]

    JuMP.@constraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
end


function constraint_converter_dc_current(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc::Int, terminals, poles, busdc_terminal_conv_poles)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)
    vdcm = _PM.var(pm, n, :vdcm)

    for terminal in terminals
        for (conv_id,pole) in busdc_terminal_conv_poles[busdc][terminal]
            if terminal != "r"
                JuMP.@constraint(pm.model, pconv_dc[conv_id][pole] == iconv_dc[conv_id][pole] * vdcm[busdc][terminal])
            else
                JuMP.@constraint(pm.model, pconv_dc[conv_id][terminal] == iconv_dc[conv_id][terminal] * vdcm[busdc][terminal])
            end
        end
    end
    for pole in poles
        JuMP.@constraint(pm.model, pconv_dcg[i][pole] == iconv_dcg[i][pole] * vdcm[busdc]["r"])
        JuMP.@constraint(pm.model, iconv_dc[i][pole] + iconv_dcg[i][pole] == 0)
    end

    JuMP.@constraint(pm.model, sum(iconv_dc[i]) == 0)
end

function constraint_converter_dc_current_sw(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc, terminals, poles, busdc_terminal_conv_poles)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)
    vdcm = _PM.var(pm, n, :vdcm)

    for terminal in terminals
        for p in poles
            for (conv_id,pole) in busdc_terminal_conv_poles[busdc[p]][terminal]
                if terminal != "r"
                    JuMP.@constraint(pm.model, pconv_dc[conv_id][pole] == iconv_dc[conv_id][pole] * vdcm[busdc[pole]][terminal])
                else
                    JuMP.@constraint(pm.model, pconv_dc[conv_id][terminal] == iconv_dc[conv_id][terminal] * vdcm[busdc[pole]][terminal])
                end
            end
        end
    end
    for pole in poles
        JuMP.@constraint(pm.model, pconv_dcg[i][pole] == iconv_dcg[i][pole] * vdcm[busdc[pole]]["r"])
        JuMP.@constraint(pm.model, iconv_dc[i][pole] + iconv_dcg[i][pole] == 0)
    end

    JuMP.@constraint(pm.model, sum(iconv_dc[i]) == 0)
end

function constraint_dc_switch_voltage_on_off_big_M_mc(pm::_PM.AbstractACPModel, n::Int, i, f_busdc, t_busdc, terminal)
    vm_fr = _PM.var(pm, n, :vdcm, f_busdc)[terminal]
    vm_to = _PM.var(pm, n, :vdcm, t_busdc)[terminal]
    z = _PM.var(pm, n, :z_dcswitch, i)
    M_vm = 1

    JuMP.@constraint(pm.model, vm_fr - vm_to <= (1-z)*M_vm)
    JuMP.@constraint(pm.model,  - (1-z)*M_vm <= vm_fr - vm_to)

    JuMP.@constraint(pm.model, vm_to - vm_fr <= (1-z)*M_vm)
    JuMP.@constraint(pm.model,  - (1-z)*M_vm <= vm_to - vm_fr)
end


"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to)
q_tf_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to)
p_tf_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)
q_tf_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)
```
"""
function constraint_conv_transformer(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, pole)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[pole]
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[pole]

    vm = _PM.var(pm, n, :vm, acbus)
    va = _PM.var(pm, n, :va, acbus)
    vmf = _PM.var(pm, n, :vmf, i)[pole]
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    ztf = rtf + im * xtf
    if transformer
        ytf = 1 / (rtf + im * xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        ac_power_flow_constraints(pm, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, vm == vmf)
    end
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(pm::_PM.AbstractACPModel, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm)
    JuMP.@constraint(pm.model, p_fr == g / (tm^2) * vm_fr^2 + -g / (tm) * vm_fr * vm_to * cos(va_fr - va_to) + -b / (tm) * vm_fr * vm_to * sin(va_fr - va_to))
    JuMP.@constraint(pm.model, q_fr == -b / (tm^2) * vm_fr^2 + b / (tm) * vm_fr * vm_to * cos(va_fr - va_to) + -g / (tm) * vm_fr * vm_to * sin(va_fr - va_to))
    JuMP.@constraint(pm.model, p_to == g * vm_to^2 + -g / (tm) * vm_to * vm_fr * cos(va_to - va_fr) + -b / (tm) * vm_to * vm_fr * sin(va_to - va_fr))
    JuMP.@constraint(pm.model, q_to == -b * vm_to^2 + b / (tm) * vm_to * vm_fr * cos(va_to - va_fr) + -g / (tm) * vm_to * vm_fr * sin(va_to - va_fr))
end

function constraint_conv_transformer_sw(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, pole)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[pole]
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[pole]

    vm = _PM.var(pm, n, :vm, acbus)#[pole]
    va = _PM.var(pm, n, :va, acbus)#[pole]
    vmf = _PM.var(pm, n, :vmf, i)[pole]
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    ztf = rtf + im * xtf
    if transformer
        ytf = 1 / (rtf + im * xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        ac_power_flow_constraints(pm, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, vm == vmf)
    end
end

"""
Converter reactor constraints
```
-pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)
-qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)
p_pr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac)
q_pr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac)
```
"""
function constraint_conv_reactor(pm::_PM.AbstractACPModel, n::Int, i::Int, rc, xc, reactor, pole)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole]
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)[pole]
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[pole]
    
    vmf = _PM.var(pm, n, :vmf, i)[pole]
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    vmc = _PM.var(pm, n, :vmc, i)[pole]
    vac = _PM.var(pm, n, :vac, i)[pole]
    
    zc = rc + im * xc
    if reactor
        yc = 1 / (zc)
        gc = real(yc)
        bc = imag(yc)
        JuMP.@constraint(pm.model, - pconv_ac == gc * vmc^2 + -gc * vmc * vmf * cos(vac - vaf) + -bc * vmc * vmf * sin(vac - vaf))
        JuMP.@constraint(pm.model, - qconv_ac == -bc * vmc^2 + bc * vmc * vmf * cos(vac - vaf) + -gc * vmc * vmf * sin(vac - vaf))
        JuMP.@constraint(pm.model, ppr_fr == gc * vmf^2 + -gc * vmf * vmc * cos(vaf - vac) + -bc * vmf * vmc * sin(vaf - vac))
        JuMP.@constraint(pm.model, qpr_fr == -bc * vmf^2 + bc * vmf * vmc * cos(vaf - vac) + -gc * vmf * vmc * sin(vaf - vac))
    else
        ppr_to = pconv_ac
        qpr_to = qconv_ac
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, vmc == vmf)
    end
end
"""
Converter filter constraints
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractACPModel, n::Int, i::Int, bv, filter, pole)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[pole]

    vmf = _PM.var(pm, n, :vmf, i)[pole]
   
    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0)
    JuMP.@constraint(pm.model, qpr_fr + qtf_to + (-bv) * filter * vmf^2 == 0)
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractACPModel, n::Int, i::Int, pole)
    p = _PM.var(pm, n, :pconv_ac, i)[pole]
    q = _PM.var(pm, n, :qconv_ac, i)[pole]
    phi = _PM.var(pm, n, :phiconv, i)[pole]

    S = conv["Pacrated"][pole]

    JuMP.constraint(pm.model, p == cos(phi) * S)
    JuMP.constraint(pm.model, q == sin(phi) * S)
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractACPModel, n::Int, busdc_grounded_convs, r_earth)
    pconv_dcg_shunt = _PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)


    for i in _PM.ids(pm, n, :busdc)
        vdcm = _PM.var(pm, n, :vdcm, i)
        for cv_id in busdc_grounded_convs[i]
            r = _PM.ref(pm, n, :convdc, cv_id)["ground_z"] + r_earth # The r_earth is kept to indicate the inclusion of earth resistance, if required in case of ground return
            if r == 0 #solid grounding
                JuMP.@constraint(pm.model, vdcm["r"] == 0)
            else
                JuMP.@constraint(pm.model, pconv_dcg_shunt[cv_id] == (1 / r) * vdcm["r"]^2)
                JuMP.@constraint(pm.model, iconv_dcg_shunt[cv_id] == (1 / r) * vdcm["r"])
            end
        end
    end
end

function constraint_BS_OTS_dcbranch_mc(pm::_PM.AbstractPowerModel, n::Int,i_1, i_2, pf, pt, qf, qt ,sw,aux)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    pf_ = _PM.var(pm, n, :p_dcgrid, pf)
    pt_ = _PM.var(pm, n, :p_dcgrid, pt)

    JuMP.@constraint(pm.model, pf_ <= (z_1+z_2)*10)
    JuMP.@constraint(pm.model, pt_ <= (z_1+z_2)*10)
    JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= pf_)
    JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= pt_)
end

