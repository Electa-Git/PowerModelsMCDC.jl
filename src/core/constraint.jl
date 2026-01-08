
"""
```
sum(p_dcgrid[a] for a in busdc_terminal_arcsdc) + sum(pconv_dc[c] for c in busdc_terminal_conv_poles) == pd
```
"""

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid_terminals, bus_convs_dc_cond, bus_convs_grounding_shunt, bus_convs_i_dc_cond)
    i_dcgrid = _PM.var(pm, n, :i_dcgrid)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    "load (-pd[k] excluded), to be thought later"

    terminals = keys(_PM.ref(pm, n, :busdc, i, "Vdc"))

    for terminal in terminals
        if terminal == "r"
            unique_convs = unique([cvs[1] for cvs in bus_convs_dc_cond[i][terminal]])
            JuMP.@constraint(pm.model,
                sum(i_dcgrid[branch][terminal] for branch in bus_arcs_dcgrid_terminals[(i, terminal)])
                + sum(iconv_dc[conv][terminal] for conv in unique_convs) # this one to be fixed still, we are getting there come on
                + sum(iconv_dcg_shunt[conv] for conv in bus_convs_grounding_shunt[i]) == 0
                )
        else
            JuMP.@constraint(pm.model,
                sum(i_dcgrid[branch][terminal] for branch in bus_arcs_dcgrid_terminals[(i, terminal)])
                + sum(iconv_dc[conv][conv_cond] for (conv,conv_cond) in bus_convs_dc_cond[i][terminal]) == 0
                ) 
        end
    end

end

function constraint_exclusivity_dc_switch_mc(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
 
    JuMP.@constraint(pm.model, z_1 + z_2 <= 1.0)
end

function constraint_ZIL_dc_switch_mc(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    
    JuMP.@constraint(pm.model, z_1 <= (1.0 - z_2))
end

function constraint_kcl_shunt_dcgrid_sw(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid_terminals, bus_convs_dc_cond, bus_convs_grounding_shunt, bus_convs_i_dc_cond, busdc_terminal_arcsdc_sw)
    i_dcgrid = _PM.var(pm, n, :i_dcgrid)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    i_dc_sw = _PM.var(pm, n, :i_dc_sw_mc)
    "load (-pd[k] excluded), to be thought later"

    terminals = keys(_PM.ref(pm, n, :busdc, i, "Vdc"))

    for terminal in terminals
        if terminal == "r"
            unique_convs = unique([cvs[1] for cvs in bus_convs_dc_cond[i][terminal]])
            JuMP.@constraint(pm.model,
                sum(i_dcgrid[branch][terminal] for branch in bus_arcs_dcgrid_terminals[(i, terminal)])
                + sum(iconv_dc[conv][terminal] for conv in unique_convs) # this one to be fixed still, we are getting there come on
                + sum(iconv_dcg_shunt[conv] for conv in bus_convs_grounding_shunt[i]) 
                + sum(i_dc_sw[(l,i,j,cond)] for (l,i,j,cond) in busdc_terminal_arcsdc_sw[(i, terminal)])
                == 0
                )
        else
            JuMP.@constraint(pm.model,
                sum(i_dcgrid[branch][terminal] for branch in bus_arcs_dcgrid_terminals[(i, terminal)])
                + sum(iconv_dc[conv][conv_cond] for (conv,conv_cond) in bus_convs_dc_cond[i][terminal]) 
                + sum(i_dc_sw[(l,i,j,cond)] for (l,i,j,cond) in busdc_terminal_arcsdc_sw[(i, terminal)])
                == 0
                ) 
        end
    end

end

"`pconv[i] == pconv`"
function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, n::Int, i, pconv_cond, cond)
    pconv_var = _PM.var(pm, n, :pconv_tf_fr, i)
    JuMP.@constraint(pm.model, pconv_var[cond] == -pconv_cond)
end

"`qconv[i] == qconv`"
function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, n::Int, i, qconv_cond, cond)
    qconv_var = _PM.var(pm, n, :qconv_tf_fr, i)
    JuMP.@constraint(pm.model, qconv_var[cond] == -qconv_cond)
end

######################### New constraints
function constraint_dc_switch_thermal_limit_mc(pm::_PM.AbstractPowerModel, n::Int, f_idx, rating)
    isw = _PM.var(pm, n, :i_dc_sw_mc, f_idx)

    JuMP.@constraint(pm.model, isw <= rating)
end

function constraint_dc_switch_current_on_off_mc(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)
    isw = _PM.var(pm, n, :i_dc_sw_mc, f_idx)
    z = _PM.var(pm, n, :z_dcswitch, i)

    isw_lb, isw_ub = _IM.variable_domain(isw)

    JuMP.@constraint(pm.model, isw <= isw_ub*z)
    JuMP.@constraint(pm.model, isw_lb*z <= isw)
end

function constraint_BS_OTS_dcbranch_mc(pm::_PM.AbstractPowerModel, n::Int,i_1, i_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    branch_dict = _PM.ref(pm, n, :branchdc)
    f_sw = _PM.ref(pm, n, :dcswitch, i_1)
    t_sw = _PM.ref(pm, n, :dcswitch, i_2)
    aux = f_sw["auxiliary"]
    orig = f_sw["original"]
    cond = f_sw["terminal"]
    i_from = _PM.var(pm, n, :i_dcgrid)
    i_to = _PM.var(pm, n, :i_dcgrid)

    if aux == "branchdc"
        i_f = (branch_dict[orig]["index"],branch_dict[orig]["fbusdc"],branch_dict[orig]["tbusdc"])
        i_t = (branch_dict[orig]["index"],branch_dict[orig]["tbusdc"],branch_dict[orig]["fbusdc"])
    
        JuMP.@constraint(pm.model, i_from[i_f][cond] <= (z_1+z_2)*10)
        JuMP.@constraint(pm.model, i_to[i_t][cond]   <= (z_1+z_2)*10)
        JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= i_from[i_f][cond])
        JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= i_to[i_t][cond]  )
    end

end


#=
function constraint_BS_OTS_dcbranch_mc(pm::_PM.AbstractPowerModel, n::Int,i_1, i_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    branch_dict = _PM.ref(pm, n, :branchdc)
    f_sw = _PM.ref(pm, n, :dcswitch, i_1)
    t_sw = _PM.ref(pm, n, :dcswitch, i_2)
    aux = f_sw["auxiliary"]
    orig = f_sw["original"]

    if aux == "branchdc"
        pf = (branch_dict[orig]["index"],branch_dict[orig]["fbusdc"],branch_dict[orig]["tbusdc"],branch_dict[orig]["terminal"])
        pt = (branch_dict[orig]["index"],branch_dict[orig]["tbusdc"],branch_dict[orig]["fbusdc"],branch_dict[orig]["terminal"])

        pf_ = _PM.var(pm, n, :p_dcgrid, pf)
        pt_ = _PM.var(pm, n, :p_dcgrid, pt)
    
        JuMP.@constraint(pm.model, pf_ <= (z_1+z_2)*10)
        JuMP.@constraint(pm.model, pt_ <= (z_1+z_2)*10)
        JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= pf_)
        JuMP.@constraint(pm.model, - (z_1+z_2)*10 <= pt_)
    end
end
=#