### the LPAC approximation
function variable_converter_filter_voltage(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle_cs(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle_cs(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

function variable_converter_filter_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=_PM.nw_id_default, bounded = true, report = true)
    vars = _PM.var(pm, nw)[:phi_vmf] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name="$(nw)_phi_vmf_$(bus)_$(cv_id)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "phi_start", pole, 0.1)
        ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])

        for bus in _PM.ids(pm, nw, :bus_conv_poles) 
            for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
                for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                    if bounded
                        JuMP.set_lower_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmin"][pole] - 1.0)
                        JuMP.set_upper_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmax"][pole] - 1.0)
                    end
                end
            end
        end
    
        poles = Dict(
            cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
            for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
        )
    
        report && sol_component_value_status(pm, nw, :convdc, :phi_vmf, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_converter_filter_voltage_angle_cs(pm::_PM.AbstractLPACModel; nw::Int=_PM.nw_id_default, bounded = true, report = true)
    vars = _PM.var(pm, nw)[:cs_vaf] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name="$(nw)_cs_vaf_$(bus)_$(cv_id)",
    start = 0
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])

    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound(vars[cv_id][pole], 0.0)
                    JuMP.set_upper_bound(vars[cv_id][pole], 1.0)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :cs_vaf, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=_PM.nw_id_default, bounded = true, report = true)
    vars = _PM.var(pm, nw)[:phi_vmc] = Dict(cv_id => JuMP.@variable(pm.model,
        [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name="$(nw)_phi_vmc_$(bus)_$(cv_id)",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "phi_start")
        ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])

        for bus in _PM.ids(pm, nw, :bus_conv_poles) 
            for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
                for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])    
                    if bounded
                        JuMP.set_lower_bound(vars[cv_id][pole],  _PM.ref(pm, nw, :convdc, cv_id)["Vmmin"][pole] - 1.0)
                        JuMP.set_upper_bound(vars[cv_id][pole],  _PM.ref(pm, nw, :convdc, cv_id)["Vmmax"][pole] - 1.0)
                    end
                end
            end
        end

        poles = Dict(
            cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
            for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
        )

    report && sol_component_value_status(pm, nw, :convdc, :phi_vmc, _PM.ids(pm, nw, :convdc), poles, vars)
end



function variable_converter_internal_voltage_angle_cs(pm::_PM.AbstractLPACModel; nw::Int=_PM.nw_id_default, bounded = true, report = true)
    vars = _PM.var(pm, nw)[:cs_vac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name="$(nw)_cs_vac",
    start = 0
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])

    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])    
                if bounded
                    JuMP.set_lower_bound(vars[cv_id][pole],  0)
                    JuMP.set_upper_bound(vars[cv_id][pole],  1)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :cs_vac, _PM.ids(pm, nw, :convdc), poles, vars)
end


function constraint_converter_losses(pm::_PM.AbstractLPACModel, n::Int, i::Int, conv, pole)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[pole] 
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[pole]
    pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[pole]
    iconv = _PM.var(pm, n, :iconv_ac, i)[pole]

    a = conv["LossA"][pole]
    b = conv["LossB"][pole]
    c = conv["LossCinv"][pole]

    JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == a + b * iconv)
    #JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b * iconv)
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
function constraint_conv_transformer(pm::_PM.AbstractLPACModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer, pole)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[pole]
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[pole]

    phi = _PM.var(pm, n, :phi, acbus)
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)[pole]
    va = _PM.var(pm, n, :va, acbus)
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    cs = _PM.var(pm, n, :cs_vaf,i)[pole]

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        lpac_power_flow_constraints(pm, gtf, btf, phi, phi_vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm, cs)
        constraint_cos_angle_diff_PWL(pm, n, cs, va, vaf)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, (1+phi) == (1+phi_vmf))
    end
end

"constraints for a voltage magnitude transformer + series impedance"

function lpac_power_flow_constraints(pm::_PM.AbstractLPACModel, g, b, phi_fr, phi_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm, cs)

    JuMP.@constraint(pm.model, p_fr ==  g/(tm^2)*(1.0 + 2*phi_fr) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*(va_fr-va_to))
    JuMP.@constraint(pm.model, q_fr == -b/(tm^2)*(1.0 + 2*phi_fr) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*(va_fr-va_to))
    JuMP.@constraint(pm.model, p_to ==  g*(1.0 + 2*phi_to) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*-(va_fr-va_to))
    JuMP.@constraint(pm.model, q_to == -b*(1.0 + 2*phi_to) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*-(va_fr-va_to))
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
function constraint_conv_reactor(pm::_PM.AbstractLPACModel, n::Int, i::Int, rc, xc, reactor, pole)
    pconv_ac  = _PM.var(pm, n, :pconv_ac, i)[pole]
    qconv_ac  = _PM.var(pm, n, :qconv_ac, i)[pole]
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[pole]
    ppr_to = - pconv_ac
    qpr_to = - qconv_ac

    phi_vmc = _PM.var(pm, n, :phi_vmc, i)[pole]
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)[pole]
    vac = _PM.var(pm, n, :vac, i)[pole]
    vaf = _PM.var(pm, n, :vaf, i)[pole]
    cs = _PM.var(pm, n, :cs_vac,i)[pole]

    phi_vmc_ub = JuMP.upper_bound(phi_vmc)
    ppr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:pconv_ac][i][pole])
    qpr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:qconv_ac][i][pole])
    Smax = sqrt(ppr_to_ub^2 + qpr_to_ub^2)
    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        lpac_power_flow_constraints(pm, gc, bc, phi_vmf, phi_vmc, vaf, vac, ppr_fr, ppr_to, qpr_fr, qpr_to, 1, cs)
        constraint_cos_angle_diff_PWL(pm, n, cs, vaf, vac)
        constraint_conv_capacity_PWL(pm, n, ppr_to, qpr_to, ppr_to_ub, qpr_to_ub, Smax)
   else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, (1+phi_vmf) == (1+phi_vmc))

    end
end

function constraint_conv_filter(pm::_PM.AbstractLPACModel, n::Int, i::Int, bv, filter, pole)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[pole]
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)[pole]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[pole]
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)[pole]
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)[pole]

    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0)
    JuMP.@constraint(pm.model, qpr_fr + qtf_to + -bv*filter*(1+2*phi_vmf) == 0)
end


function constraint_converter_current(pm::_PM.AbstractLPACModel, n::Int, i::Int, pole)
    #phi_vmc = _PM.var(pm, n, :phi_vmc, i)
    #pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    #qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    #iconv = _PM.var(pm, n, :iconv_ac, i)
    #conv = _PM.ref(pm, n, :convdc, i)
    #Imax = conv["Imax"][pole]
    #println("Imax: ", Imax)
    #JuMP.@constraint(pm.model, iconv <= Imax)
end

function constraint_converter_dc_current(pm::_PM.AbstractLPACModel, n::Int, i::Int, busdc::Int, terminals, poles, busdc_terminal_conv_poles)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dcg = _PM.var(pm, n, :pconv_dcg)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg = _PM.var(pm, n, :iconv_dcg)

    #vdcm = _PM.var(pm, n, :vdcm)

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
        #vdcm = 0.0
        #JuMP.@constraint(pm.model, pconv_dcg[i][pole] == iconv_dcg[i][pole]) # to be checked here
        JuMP.@constraint(pm.model, iconv_dc[i][pole] + iconv_dcg[i][pole] == 0)
    end

    JuMP.@constraint(pm.model, sum(iconv_dc[i]) == 0)
end



function constraint_conv_capacity_PWL(pm::_PM.AbstractLPACModel, n::Int, ppr_to, qpr_to, Umax, Imax, Smax)
    np = 20 #no. of segments, can be passed as an argument later
    l = 0
    for i = 1:np
        a= Smax*sin(l)
        b = Smax*cos(l)
        JuMP.@constraint(pm.model, a*ppr_to + b*qpr_to <= Smax^2) #current and voltage bounds to be proper to use Umax*Imax because Umax*Imax == Smax
        l = l + 2*pi/np
    end
end

function constraint_cos_angle_diff_PWL(pm::_PM.AbstractLPACModel, n::Int, cs, va_fr, va_to)
    nb = 20 #no. of segments, can be passed as an argument later
    l = -pi/6
    h = pi/6
    inc = (h-l)/(nb+1)
    a = l + inc
    diff = va_fr - va_to
    for i = 1:nb
        JuMP.@constraint(pm.model, cs <= -sin(a)*(diff-a) + cos(a))
        a = a + inc
    end
end

#function add_dcconverter_voltage_setpoint(sol, pm::_PM.AbstractLPACModel)
#    _PM.add_setpoint!(sol, pm, "convdc", "vmconv", :phi_vmc, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
#    _PM.add_setpoint!(sol, pm, "convdc", "vmfilt", :phi_vmf, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
#    _PM.add_setpoint!(sol, pm, "convdc", "vaconv", :vac, status_name="islcc", inactive_status_value = 4)
#    _PM.add_setpoint!(sol, pm, "convdc", "vafilt", :vaf, status_name="islcc", inactive_status_value = 4)
#end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractLPACModel, n::Int, busdc_grounded_convs, r_earth)
    pconv_dcg_shunt = _PM.var(pm, n, :pconv_dcg_shunt)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    #vref = -0.0

    for i in _PM.ids(pm, n, :busdc)
        phi = _PM.var(pm, n, :phi_vdcm, i)
        for c in busdc_grounded_convs[i]
            r = _PM.ref(pm, n, :convdc, c)["ground_z"] + r_earth # The r_earth is kept to indicate the inclusion of earth resistance, if required in case of ground return
            if r == 0 #solid grounding
                JuMP.@constraint(pm.model, phi["r"] == 0)
            else
                JuMP.@constraint(pm.model, pconv_dcg_shunt[c] == iconv_dcg_shunt[c])
                JuMP.@constraint(pm.model, iconv_dcg_shunt[c] == (1 / r) * (1 + phi["r"]))
            end
        end
    end
end









