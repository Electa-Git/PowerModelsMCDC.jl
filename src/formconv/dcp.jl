"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::_PM.AbstractDCPModel, n::Int,  i::Int, a, b, c, plmax, cond)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond] #cond defined over conveter
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)[cond]
    pconv_dcg= _PM.var(pm, n, :pconv_dcg, i)[cond]

    display("reached to losses")
    display("$pconv_ac; $pconv_dc; $pconv_dcg")
    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac/v # can actually be negative, not a very nice model...
    if pm.setting["conv_losses_mp"] == true
        # _PM.con(pm, n, :conv_loss)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac ...a + b*cm_conv_ac)
            # JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == 0 )
        display(JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg == a + b*cm_conv_ac ))
    else
        # _PM.con(pm, n, :conv_loss)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a + b*cm_conv_ac )
        # _PM.con(pm, n, :conv_loss_aux)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a - b*cm_conv_ac )
        # _PM.con(pm, n, :conv_loss_plmax)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc <= plmax)
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a + b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg >= a - b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc + pconv_dcg <= plmax)
    end
end

function constraint_converter_dc_ground(pm::_PM.AbstractDCPModel, n::Int,  i::Int, pconv_dc,pconv_dcg,total_conv_cond)
    # constraint_converter_dc_ground(pm, nw, i,pconv_dc,pconv_dcg,total_conv_cond)
    # JuMP.@constraint(pm.model, pconv_dc[total_conv_cond+1]==sum(pconv_dcg[cond_g] for cond_g=1:total_conv_cond))
    display(JuMP.@constraint(pm.model, pconv_dc[total_conv_cond+1]==sum(pconv_dcg[cond_g] for cond_g=1:total_conv_cond)))
end

function constraint_converter_dc_ground_shunt_kcl(pm::_PM.AbstractDCPModel, n::Int)
    pconv_dcg_shunt=_PM.var(pm, n, :pconv_dcg_shunt)
    bus_convs_grounding_shunt=_PM.ref(pm, n, :bus_convs_grounding_shunt)

    # sum(pconv_dcg_shunt[c] for c in bus_convs_grounding_shunt[(i, k)
     # for i in _PM.ids(pm, nw, :convdc)
     # display(pconv_dcg_shunt)
     # display(bus_convs_grounding_shunt)
     #
         # JuMP.@constraint(pm.model, sum(pconv_dcg_shunt[c] for (i,c) in bus_convs_grounding_shunt)==0)
         display(JuMP.@constraint(pm.model, sum(sum(pconv_dcg_shunt[c] for c in bus_convs_grounding_shunt[(i, 3)]) for i in _PM.ids(pm, n, :busdc))==0))
end



function constraint_converter_dc_current(pm::_PM.AbstractDCPModel, n::Int, i::Int)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    vdcm = 1.0

    dc_bus=_PM.ref(pm, n, :convdc,i)["busdc_i"]
    conv_cond=_PM.ref(pm, n, :convdc,i)["conductors"]
    bus_convs_dc_cond =  _PM.ref(pm, n, :bus_convs_dc_cond)

     total_cond = _PM.ref(pm, n, :busdc,i)["conductors"]
     for k in 1:total_cond
        for (c,d) in bus_convs_dc_cond[(dc_bus, k)]
            if k==1
                vdcm= 1 #metallic return volatage is taken 0
            elseif k==2
                vdcm= -1
            elseif k==3
                vdcm= -0
            end

            if c==i
                display(JuMP.@constraint(pm.model, pconv_dc[c][d]==iconv_dc[c][d]*vdcm))
            end
        end
    end

    display(JuMP.@constraint(pm.model, sum(iconv_dc[i][c] for c in 1:conv_cond+1)==0))

    # if conv_cond==2
    #     display(JuMP.@constraint(pm.model, sign(iconv_dc[i][1]) + sign(iconv_dc[i][2])==0 ) )
    # end
end
"""
Converter transformer constraints

```
p_tf_fr == -btf*(v^2)/tm*(va-vaf)
p_tf_to == -btf*(v^2)/tm*(vaf-va)
```
"""
function constraint_conv_transformer(pm::_PM.AbstractDCPModel, n::Int,  i::Int, rtf, xtf, acbus, tm, transformer, cond)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]

    vaf = _PM.var(pm, n, :vaf, i)[cond]
    va = _PM.var(pm, n, :va, acbus)

    if transformer
         btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = JuMP.@constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        # _PM.con(pm, n, :conv_tf_p_to)[i] = JuMP.@constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
        display(JuMP.@constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf)))
        JuMP.@constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
    else
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = JuMP.@constraint(pm.model, va == vaf)
        # _PM.con(pm, n, :conv_tf_p_to)[i] = JuMP.@constraint(pm.model, ptf_fr + ptf_to  == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, ptf_fr + ptf_to  == 0)
    end
end
"""
Converter reactor constraints

```
p_pr_fr == -bc*(v^2)*(vaf-vac)
pconv_ac == -bc*(v^2)*(vac-vaf)
```
"""
function constraint_conv_reactor(pm::_PM.AbstractDCPModel, n::Int,  i::Int, rc, xc, reactor, cond)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)[cond]
    ppr_to = - pconv_ac
    vaf = _PM.var(pm, n, :vaf, i)[cond]
    vac = _PM.var(pm, n, :vac, i)[cond]
    # display(ppr_fr)
    # display(pconv_ac)
    # display(vaf)
    # display(vac)§
    if reactor
        display("reactor is present")
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        # _PM.con(pm, n, :conv_pr_p)[i] = JuMP.@constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        # _PM.con(pm, n, :conv_pr_p_to)[i] = JuMP.@constraint(pm.model, pconv_ac == -bc*(v^2)*(vac-vaf))
        display(JuMP.@constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac)))
        JuMP.@constraint(pm.model, ppr_to == -bc*(v^2)*(vac-vaf))
    else
        display("reactor is NOT there")
        # _PM.con(pm, n, :conv_pr_p)[i] =  JuMP.@constraint(pm.model, vac == vaf)
        # _PM.con(pm, n, :conv_pr_p_to)[i] = JuMP.@constraint(pm.model, ppr_fr + pconv_ac  == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, ppr_fr + ppr_to  == 0)
    end
end
"""
Converter filter constraints (no active power losses)
```
p_pr_fr + p_tf_to == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractDCPModel, n::Int,  i::Int, bv, filter, cond)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)[cond]
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)[cond]

    # _PM.con(pm, n, :conv_kcl_p)[i] = JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
end
"""
Converter current constraint (not applicable)
```
```
"""
function constraint_converter_current(pm::_PM.AbstractDCPModel, n::Int,  i::Int, Umax, Imax, cond)
    # not used
end
# function variable_dc_converter(pm::_PM.AbstractDCPModel; kwargs...)
#     variable_converter_active_power(pm; kwargs...)
#     variable_dcside_power(pm; kwargs...)
#     variable_converter_filter_voltage(pm; kwargs...)
#     variable_converter_internal_voltage(pm; kwargs...)
#     variable_converter_to_grid_active_power(pm; kwargs...)
#
#     variable_conv_transformer_active_power_to(pm; kwargs...)
#     variable_conv_reactor_active_power_from(pm; kwargs...)
# end
#
# function variable_converter_filter_voltage(pm::_PM.AbstractDCPModel; kwargs...)
#     variable_converter_filter_voltage_angle(pm; kwargs...)
# end
#
#
# function variable_converter_internal_voltage(pm::_PM.AbstractDCPModel; kwargs...)
#     variable_converter_internal_voltage_angle(pm; kwargs...)
# end
"""
Converter reactive power setpoint constraint (PF only, not applicable)
```
```
"""
function constraint_reactive_conv_setpoint(pm::_PM.AbstractDCPModel, n::Int,  i, qconv)
end
"""
Converter firing angle constraint (not applicable)
```
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractDCPModel, n::Int,  i::Int, S, P1, Q1, P2, Q2)
end
"""
Converter droop constraint (not applicable)
```
```
"""
function constraint_dc_droop_control(pm::_PM.AbstractDCPModel, n::Int,  i::Int, busdc_i, vref_dc, pref_dc, k_droop)
end
######################## TNEP Constraints #################
