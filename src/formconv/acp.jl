"""
Creates lossy converter model between AC and DC grid
```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses(pm::_PM.AbstractACPModel, n::Int,  i::Int, a, b, c, plmax, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond] #cond defined over conveter
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    pconv_dcg= _PM.var(pm, n, :pconv_dcg, i)[cond]
    iconv = _PM.var(pm, n, :iconv_ac, i)[cond]

        (JuMP.@NLconstraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == a + b*iconv + c*iconv^2 ))
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::_PM.AbstractACPModel, n::Int, i::Int, Umax, Imax, cond)
    vmc = _PM.var(pm, n, :vmc, i)[cond]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)[cond]
    iconv = _PM.var(pm, n, :iconv_ac, i)[cond]

    (JuMP.@NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2))
end

function constraint_converter_dc_current(pm::_PM.AbstractACPModel, n::Int, i::Int)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)
    vdcm = _PM.var(pm, n, :vdcm)


    dc_bus=_PM.ref(pm, n, :convdc,i)["busdc_i"]

    conv_cond=_PM.ref(pm, n, :convdc,i)["conductors"]
    bus_convs_dc_cond =  _PM.ref(pm, n, :bus_convs_dc_cond)

     total_cond = _PM.ref(pm, n, :busdc,dc_bus)["conductors"]
     for k in 1:total_cond
        for (c,d) in bus_convs_dc_cond[(dc_bus, k)]
            if c==i

                # display("c,d,k == $c,$d,$k")
                (JuMP.@NLconstraint(pm.model, pconv_dc[c][d]==iconv_dc[c][d]*vdcm[dc_bus][k]))
            end
        end
    end

  # neutral is always connected at bus conductor "3"
  # display("conv_cond= $conv_cond")
    for g in 1:conv_cond
        (JuMP.@NLconstraint(pm.model, pconv_dcg[i][g]==iconv_dcg[i][g]*vdcm[dc_bus][3]))
        (JuMP.@NLconstraint(pm.model, iconv_dc[i][g]+iconv_dcg[i][g]==0))
    end

    (JuMP.@NLconstraint(pm.model, sum(iconv_dc[i][c] for c in 1:conv_cond+1)==0))

end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractACPModel, n::Int)
    pconv_dcg_shunt=_PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt=_PM.var(pm, n, :iconv_dcg_shunt)

    bus_convs_grounding_shunt=_PM.ref(pm, n, :bus_convs_grounding_shunt)
    r_earth=0
    
         for i in _PM.ids(pm, n, :busdc)
            vdc= _PM.var(pm, n,  :vdcm,i)
             for c in bus_convs_grounding_shunt[(i, 3)]
                 conv = _PM.ref(pm, n, :convdc, c)
                 r=conv["ground_z"]+ r_earth
                 if r==0
                     JuMP.@NLconstraint(pm.model, pconv_dcg_shunt[c]==0)
                     JuMP.@NLconstraint(pm.model, iconv_dcg_shunt[c]==0)
                 else
                     (JuMP.@NLconstraint(pm.model, pconv_dcg_shunt[c]==(1/r)*vdc[3]^2))
                     (JuMP.@NLconstraint(pm.model, iconv_dcg_shunt[c]==(1/r)*vdc[3]))
                end
             end
         end
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
function constraint_conv_transformer(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, cond)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[cond]
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[cond]

    vm = _PM.var(pm, n, :vm, acbus)
    va = _PM.var(pm, n, :va, acbus)
    vmf = _PM.var(pm, n, :vmf, i)[cond]
    vaf = _PM.var(pm, n, :vaf, i)[cond]

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, vm == vmf)
    end
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(model, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm)
    c1 = JuMP.@NLconstraint(model, p_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c2 = JuMP.@NLconstraint(model, q_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c3 = JuMP.@NLconstraint(model, p_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
    c4 = JuMP.@NLconstraint(model, q_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
    return c1, c2, c3, c4
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
function constraint_conv_reactor(pm::_PM.AbstractACPModel, n::Int, i::Int, rc, xc, reactor, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)[cond]
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[cond]

    vmf = _PM.var(pm, n, :vmf, i)[cond]
    vaf = _PM.var(pm, n, :vaf, i)[cond]
    vmc = _PM.var(pm, n, :vmc, i)[cond]
    vac = _PM.var(pm, n, :vac, i)[cond]

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        JuMP.@NLconstraint(pm.model, -pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf))
        JuMP.@NLconstraint(pm.model, -qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf))
        JuMP.@NLconstraint(pm.model, ppr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac))
        JuMP.@NLconstraint(pm.model, qpr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac))
    else
        ppr_to = -pconv_ac
        qpr_to = -qconv_ac
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
function constraint_conv_filter(pm::_PM.AbstractACPModel, n::Int, i::Int, bv, filter, cond)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[cond]

    vmf = _PM.var(pm, n, :vmf, i)[cond]

    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@NLconstraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0)
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractACPModel, n::Int, i::Int, S, P1, Q1, P2, Q2, cond)
    p = _PM.var(pm, n, :pconv_ac, i)[cond]
    q = _PM.var(pm, n, :qconv_ac, i)[cond]
    phi = _PM.var(pm, n, :phiconv, i)[cond]

    JuMP.@NLconstraint(pm.model,   p == cos(phi) * S)
    JuMP.@NLconstraint(pm.model,   q == sin(phi) * S)
end

function constraint_dc_droop_control(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc_i, vref_dc, pref_dc, k_droop, cond)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    vdc = _PM.var(pm, n, :vdcm, busdc_i)[cond]

    JuMP.@constraint(pm.model, pconv_dc == pref_dc - sign(pref_dc) * 1 / k_droop * (vdc - vref_dc))
end
