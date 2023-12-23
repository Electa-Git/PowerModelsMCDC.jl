"All converter variables"
function variable_mcdc_converter(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_tranformer_flow(pm; kwargs...)
    variable_conv_reactor_flow(pm; kwargs...)

    variable_converter_active_power(pm; kwargs...)
    variable_converter_reactive_power(pm; kwargs...)
    variable_acside_current(pm; kwargs...)
    variable_dcside_current(pm; kwargs...)
    variable_dcside_current_ground(pm; kwargs...)
    variable_dcside_current_grounding_shunt(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
    variable_dcside_ground_power(pm; kwargs...)
    variable_dcside_grounding_shunt_power(pm; kwargs...)
    variable_converter_firing_angle(pm; kwargs...)

    variable_converter_filter_voltage(pm; kwargs...)
    variable_converter_internal_voltage(pm; kwargs...)

    variable_converter_to_grid_active_power(pm; kwargs...)
    variable_converter_to_grid_reactive_power(pm; kwargs...)
end

function variable_conv_tranformer_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_transformer_reactive_power_to(pm; kwargs...)
end

function variable_conv_reactor_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
    variable_conv_reactor_reactive_power_from(pm; kwargs...)
end

"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_converter_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:pconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_ac_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], convdc["Pacmin"][first(conductors[i])])
            JuMP.set_upper_bound.(vars[i], convdc["Pacmax"][first(conductors[i])])
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :pconv, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:qconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_qconv_ac_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], convdc["Qacmin"][first(conductors[i])])
            JuMP.set_upper_bound.(vars[i], convdc["Qacmax"][first(conductors[i])])
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :qconv, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:pconv_tf_to] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_tf_to_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Pacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Pacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :ptf_to, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:qconv_tf_to] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_qconv_tf_to__$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Qacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Qacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :qtf_to, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_pr_fr_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Pacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Pacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :ppr_fr, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:qconv_pr_fr] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_qconv_pr_fr_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Qacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Qacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :qpr_fr, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:pconv_tf_fr] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_tf_fr_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Pacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Pacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :pgrid, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:qconv_tf_fr] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_qconv_tf_fr_$(i)"
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    for (i, convdc) in _PM.ref(pm, nw, :convdc)
        JuMP.set_start_value.(vars[i], comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", first(conductors[i]), 1.0))
        if bounded
            JuMP.set_lower_bound.(vars[i], -convdc["Qacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Qacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :qgrid, _PM.ids(pm, nw, :convdc), conductors, vars)
end

function variable_dcside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_dc_cond)
    vars = _PM.var(pm, nw)[:iconv_dc] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_iconv_dc_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded # The current rating of the metallic return converter terminal is set equal to the rating of the first converter pole
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            active_pole = first(conductors[i])[1:end-1]
            JuMP.set_lower_bound.(vars[i], -vcat(convdc["Imax"][active_pole], first(convdc["Imax"])))
            JuMP.set_upper_bound.(vars[i], vcat(convdc["Imax"][active_pole], first(convdc["Imax"])))
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :iconv_dc, _PM.ids(pm, nw, :convdc), conductors, vars)
end

function variable_dcside_current_ground(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:iconv_dcg] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_iconv_dcg_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], -convdc["Imax"][first(conductors[i])])
            JuMP.set_upper_bound.(vars[i], convdc["Imax"][first(conductors[i])])
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :iconv_dcg, _PM.ids(pm, nw, :convdc), conductors, vars)
end

function variable_dcside_current_grounding_shunt(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:iconv_dcg_shunt] = Dict(i => JuMP.@variable(pm.model,
        base_name = "$(nw)_iconv_dcg_shunt_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vars[i], -convdc["Imax"][1] * 0.1 * bigM * convdc["ground_type"])
            JuMP.set_upper_bound(vars[i], convdc["Imax"][1] * 0.1 * bigM * convdc["ground_type"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dcg_shunt, _PM.ids(pm, nw, :convdc), vars)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    conductors = _PM.ref(pm, nw, :convs_dc_cond)
    vars = _PM.var(pm, nw)[:pconv_dc] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_dc_$(i)",
        start = 1.0 #comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded # Active power bounds are not defined for the converter terminal related to the metallic return
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            active_pole = first(conductors[i])[1:end-1]
            JuMP.set_lower_bound.(vars[i][active_pole], -convdc["Pacrated"][active_pole] * bigM)
            JuMP.set_upper_bound.(vars[i][active_pole], convdc["Pacrated"][active_pole] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :pdc, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `pconv_dcg[j]` for `j` in `convdc`"
function variable_dcside_ground_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:pconv_dcg] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_pconv_dcg_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], -convdc["Pacrated"][first(conductors[i])] * bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Pacrated"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :pdcg, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `pconv_dcg_shunt[j]` for `j` in `convdc`"
function variable_dcside_grounding_shunt_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:pconv_dcg_shunt] = Dict(i => JuMP.@variable(pm.model,
        base_name = "$(nw)_pconv_dcg_shunt_$(i)",
        start = 1.0 #comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded # The grounding shunt power is bounded by using the limits of the positive (i.e. first) pole
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vars[i], -convdc["Pacrated"][1] * 0.1 * bigM * convdc["ground_type"])
            JuMP.set_upper_bound(vars[i], convdc["Pacrated"][1] * 0.1 * bigM * convdc["ground_type"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :pdcg_shunt, _PM.ids(pm, nw, :convdc), vars)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:phiconv] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_phiconv_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], 0)
            JuMP.set_upper_bound.(vars[i], pi)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :phi, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:iconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_iconv_ac_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], 0)
            JuMP.set_upper_bound.(vars[i], convdc["Imax"][first(conductors[i])])
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :iconv, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractWModels; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    ic = _PM.var(pm, nw)[:iconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_iconv_ac_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    icsq = _PM.var(pm, nw)[:iconv_ac_sq] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_iconv_ac_sq_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ic[c], 0)
            JuMP.set_upper_bound.(ic[c], convdc["Imax"])
            JuMP.set_lower_bound.(icsq[c], 0)
            JuMP.set_upper_bound.(icsq[c], convdc["Imax"]^2)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_ac, _PM.ids(pm, nw, :convdc), ic)
    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_ac_sq, _PM.ids(pm, nw, :convdc), icsq)
end

function variable_converter_filter_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end

"variable: `vmf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # only internal converter voltage is strictly regulated
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:vmf] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_vmf_$(i)",
        start = 0 # start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], convdc["Vmmin"][first(conductors[i])] / bigM)
            JuMP.set_upper_bound.(vars[i], convdc["Vmmax"][first(conductors[i])] * bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :vmfilt, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:vaf] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_vaf_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], -bigM)
            JuMP.set_upper_bound.(vars[i], bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :vafilt, _PM.ids(pm, nw, :convdc), conductors, vars)
end

function variable_converter_internal_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:vmc] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_vmc_$(i)",
        start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], convdc["Vmmin"][first(conductors[i])])
            JuMP.set_upper_bound.(vars[i], convdc["Vmmax"][first(conductors[i])])
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :vmconv, _PM.ids(pm, nw, :convdc), conductors, vars)
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #
    conductors = _PM.ref(pm, nw, :convs_ac_cond)
    vars = _PM.var(pm, nw)[:vac] = Dict(i => JuMP.@variable(pm.model,
        [first(conductors[i])], base_name = "$(nw)_vac_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vars[i], -bigM)
            JuMP.set_upper_bound.(vars[i], bigM)
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :vaconv, _PM.ids(pm, nw, :convdc), conductors, vars)
end
