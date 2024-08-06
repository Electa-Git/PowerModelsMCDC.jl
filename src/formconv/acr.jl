"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == (vrc[i]^2 + vic[i]^2) * iconv_sq[i]
```
"""
function constraint_converter_current(pm::_PM.AbstractACRModel, n::Int, i::Int, Umax, Imax, cond)
    vrc = _PM.var(pm, n, :vrc, i)[cond]
    vic = _PM.var(pm, n, :vic, i)[cond]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)[cond]
    iconv = _PM.var(pm, n, :iconv_ac, i)[cond]

    JuMP.@NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == (vrc^2+vic^2) * iconv^2)
end
"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*(vr_fr^2+vi_fr^2) + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
q_tf_fr == -b/(tm^2)*(vr_fr^2+vi_fr^2) +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
p_tf_to ==  g*(vr_to^2+vi_to^2)        + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
q_tf_to == -b*(vr_to^2+vi_to^2)        +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
```
"""
function constraint_conv_transformer(pm::_PM.AbstractACRModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, cond)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[cond]
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[cond]

    vr = _PM.var(pm, n, :vr, acbus) # why do these have no ``cond" idx?
    vi = _PM.var(pm, n, :vi, acbus) # why do these have no ``cond" idx?
    vrf = _PM.var(pm, n, :vrf, i)[cond]
    vif = _PM.var(pm, n, :vif, i)[cond] 

    # ztf = rtf + im * xtf
    if transformer
        ytf = 1 / (rtf + im * xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        ac_power_flow_constraints(pm, gtf, btf, gtf_sh, vr, vrf, vi, vif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, vr == vrf)
        JuMP.@constraint(pm.model, vi == vif)
    end
end
"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*(vr_fr^2+vi_fr^2) + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
q_tf_fr == -b/(tm^2)*(vr_fr^2+vi_fr^2) +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
p_tf_to ==  g*(vr_to^2+vi_to^2)        + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
q_tf_to == -b*(vr_to^2+vi_to^2)        +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
```
"""
function ac_power_flow_constraints(pm::_PM.AbstractACRModel, g, b, gsh_fr, vr, vrf, vi, vif, p_fr, p_to, q_fr, q_to, tm)
    JuMP.@NLconstraint(pm.model, p_fr ==  g / tm^2 * (vr^2 + vi^2) + -g / tm * (vr * vrf + vi * vif) + -b / tm *   (vi * vrf - vr * vif)  )
    JuMP.@NLconstraint(pm.model, q_fr == -b / tm^2 * (vr^2 + vi^2) +  b / tm * (vr * vrf + vi * vif) + -g / tm *   (vi * vrf - vr * vif)  )
    JuMP.@NLconstraint(pm.model, p_to ==  g * (vrf^2 + vif^2)      + -g / tm * (vr * vrf + vi * vif) + -b / tm * (-(vi * vrf - vr * vif)) )
    JuMP.@NLconstraint(pm.model, q_to == -b * (vrf^2 + vif^2)      +  b / tm * (vr * vrf + vi * vif) + -g / tm * (-(vi * vrf - vr * vif)) )
end
"""
Converter reactor constraints
```
-pconv_ac == gc*(vrc^2 + vic^2) + -gc*(vrc * vrf + vic * vif) + -bc*(vic * vrf - vrc * vif)
-qconv_ac ==-bc*(vrc^2 + vic^2) +  bc*(vrc * vrf + vic * vif) + -gc*(vic * vrf - vrc * vif)
p_pr_fr ==  gc *(vrf^2 + vif^2) + -gc *(vrc * vrf + vic * vif) + -bc *(-(vic * vrf - vrc * vif))
q_pr_fr == -bc *(vrf^2 + vif^2) +  bc *(vrc * vrf + vic * vif) + -gc *(-(vic * vrf - vrc * vif))
```
"""
function constraint_conv_reactor(pm::_PM.AbstractACRModel, n::Int, i::Int, rc, xc, reactor)
    pconv_ac = _PM.var(pm, n,  :pconv_ac, i)[cond]
    qconv_ac = _PM.var(pm, n,  :qconv_ac, i)[cond]
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)[cond]
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)[cond]

    vrf = _PM.var(pm, n, :vrf, i)[cond] 
    vif = _PM.var(pm, n, :vif, i)[cond] 
    vrc = _PM.var(pm, n, :vrc, i)[cond] 
    vic = _PM.var(pm, n, :vic, i)[cond] 

    # zc = rc + im*xc
    if reactor
        yc = 1/(rc + im*xc)
        gc = real(yc)
        bc = imag(yc)                                      
        JuMP.@constraint(pm.model, - pconv_ac ==  gc * (vrc^2 + vic^2) + -gc * (vrc * vrf + vic * vif) + -bc * (vic * vrf - vrc * vif))  
        JuMP.@constraint(pm.model, - qconv_ac == -bc * (vrc^2 + vic^2) +  bc * (vrc * vrf + vic * vif) + -gc * (vic * vrf - vrc * vif)) 
        JuMP.@constraint(pm.model, ppr_fr ==  gc * (vrf^2 + vif^2) + -gc * (vrc * vrf + vic * vif) + -bc * (-(vic * vrf - vrc * vif)))
        JuMP.@constraint(pm.model, qpr_fr == -bc * (vrf^2 + vif^2) +  bc * (vrc * vrf + vic * vif) + -gc * (-(vic * vrf - vrc * vif)))
    else
        ppr_to = - pconv_ac
        qpr_to = - qconv_ac
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vrc == vrf)
        JuMP.@constraint(pm.model, vic == vif)
    end
end
"""
Converter filter constraints
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *(vrf^2 + vif^2) == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractACRModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[cond]

    vrf = _PM.var(pm, n, :vrf, i)[cond]
    vif = _PM.var(pm, n, :vif, i)[cond]
    
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *(vrf^2 + vif^2) == 0)
end