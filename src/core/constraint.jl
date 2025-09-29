
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
                #+ sum(iconv_dc[conv][terminal] for (conv,conv_cond) in bus_convs_dc_cond[i][terminal]) # this one to be fixed still, we are getting there come on
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
