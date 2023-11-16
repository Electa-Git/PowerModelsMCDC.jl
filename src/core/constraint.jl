"do nothing, this model does not have complex voltage constraints"
function constraint_voltage_dc(pm::_PM.AbstractPowerModel, n::Int)
end

"""
```
sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd
```
"""

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, n::Int, i::Int, pd, total_cond, bus_arcs_dcgrid_cond, bus_convs_dc_cond, bus_convs_grounding_shunt)
    i_dcgrid = _PM.var(pm, n, :i_dcgrid)
    iconv_dc = _PM.var(pm, n, :iconv_dc)
    iconv_dcg_shunt = _PM.var(pm, n, :iconv_dcg_shunt)
    "load (-pd[k] excluded), to be thought later"

    for bus_cond in 1:total_cond
        JuMP.@constraint(pm.model,
            sum(i_dcgrid[conv][conv_cond] for (conv, conv_cond) in bus_arcs_dcgrid_cond[(i, bus_cond)])
            + sum(iconv_dc[conv][conv_cond] for (conv, conv_cond) in bus_convs_dc_cond[(i, bus_cond)])
            + sum(iconv_dcg_shunt[conv] for conv in bus_convs_grounding_shunt[(i, bus_cond)]) == 0
            )
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
