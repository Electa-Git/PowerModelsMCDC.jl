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
    pc = _PM.var(pm, nw)[:pconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_pconv_ac_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(pc[c], convdc["Pacmin"])
            JuMP.set_upper_bound.(pc[c], convdc["Pacmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :pconv, _PM.ids(pm, nw, :convdc), pc)
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    qc = _PM.var(pm, nw)[:qconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_qconv_ac_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qc[c], convdc["Qacmin"])
            JuMP.set_upper_bound.(qc[c], convdc["Qacmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :qconv, _PM.ids(pm, nw, :convdc), qc)
end

"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2

    ptfto = _PM.var(pm, nw)[:pconv_tf_to] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_pconv_tf_to_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ptfto[c], -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(ptfto[c], convdc["Pacrated"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ptf_to, _PM.ids(pm, nw, :convdc), ptfto)
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    qtfto = _PM.var(pm, nw)[:qconv_tf_to] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_qconv_tf_to__$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qtfto[c], -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qtfto[c], convdc["Qacrated"] * bigM)

        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :qtf_to, _PM.ids(pm, nw, :convdc), qtfto)
end

"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_pconv_pr_fr_$(i)",
        start = -comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(pprfr[c], -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(pprfr[c], convdc["Pacrated"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ppr_fr, _PM.ids(pm, nw, :convdc), pprfr)
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    qprfr = _PM.var(pm, nw)[:qconv_pr_fr] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_qconv_pr_fr_$(i)",
        start = -comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qprfr[c], -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qprfr[c], convdc["Qacrated"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :qpr_fr, _PM.ids(pm, nw, :convdc), qprfr)
end

"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    ptffr = _PM.var(pm, nw)[:pconv_tf_fr] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_pconv_tf_fr_$(i)",
        start = -comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ptffr[c], -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(ptffr[c], convdc["Pacrated"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :pgrid, _PM.ids(pm, nw, :convdc), ptffr)
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    qtffr = _PM.var(pm, nw)[:qconv_tf_fr] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_qconv_tf_fr_$(i)",
        start = -comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qtffr[c], -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qtffr[c], convdc["Qacrated"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :qgrid, _PM.ids(pm, nw, :convdc), qtffr)
end

function variable_dcside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    icdc = _PM.var(pm, nw)[:iconv_dc] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]+1], base_name = "$(nw)_iconv_dc_$(i)",
        start = 1.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            conv_cond = _PM.ref(pm, nw, :convdc)[i]["conductors"]
            for c in 1:conv_cond
                JuMP.set_lower_bound.(icdc[i][c], -
                _PM.ref(pm, nw, :convdc)[i]["Imax"][c])
                JuMP.set_upper_bound.(icdc[i][c], _PM.ref(pm, nw, :convdc)[i]["Imax"][c])
            end
            JuMP.set_lower_bound.(icdc[i][conv_cond+1], -_PM.ref(pm, nw, :convdc)[i]["Imax"][1])
            JuMP.set_upper_bound.(icdc[i][conv_cond+1], _PM.ref(pm, nw, :convdc)[i]["Imax"][1])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dc, _PM.ids(pm, nw, :convdc), icdc)

end

function variable_dcside_current_ground(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    icdcg = _PM.var(pm, nw)[:iconv_dcg] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_iconv_dcg_$(i)",
        start = 0.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            conv_cond = _PM.ref(pm, nw, :convdc)[i]["conductors"]
            for c in 1:conv_cond
                JuMP.set_lower_bound.(icdcg[i][c], -_PM.ref(pm, nw, :convdc)[i]["Imax"][c])
                JuMP.set_upper_bound.(icdcg[i][c], _PM.ref(pm, nw, :convdc)[i]["Imax"][c])
            end
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dcg, _PM.ids(pm, nw, :convdc), icdcg)
end

function variable_dcside_current_grounding_shunt(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    icdcg_shunt = _PM.var(pm, nw)[:iconv_dcg_shunt] = Dict(i => JuMP.@variable(pm.model,
        base_name = "$(nw)_iconv_dcg_shunt_$(i)",
        start = 0.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            JuMP.set_lower_bound.(icdcg_shunt[i], -_PM.ref(pm, nw, :convdc)[i]["Imax"][1] * 0.1 * bigM * _PM.ref(pm, nw, :convdc)[i]["ground_type"])
            JuMP.set_upper_bound.(icdcg_shunt[i], _PM.ref(pm, nw, :convdc)[i]["Imax"][1] * 0.1 * bigM * _PM.ref(pm, nw, :convdc)[i]["ground_type"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dcg_shunt, _PM.ids(pm, nw, :convdc), icdcg_shunt)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    pcdc = _PM.var(pm, nw)[:pconv_dc] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]+1], base_name = "$(nw)_pconv_dc_$(i)",
        start = 1.0 #comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            for c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]
                JuMP.set_lower_bound.(pcdc[i][c], -_PM.ref(pm, nw, :convdc)[i]["Pacrated"][c] * bigM)
                JuMP.set_upper_bound.(pcdc[i][c], _PM.ref(pm, nw, :convdc)[i]["Pacrated"][c] * bigM)
            end
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :pdc, _PM.ids(pm, nw, :convdc), pcdc)
end

"variable: `pconv_dcg[j]` for `j` in `convdc`"
function variable_dcside_ground_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    pcdcg = _PM.var(pm, nw)[:pconv_dcg] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_pconv_dcg_$(i)",
        start = 0.0
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            for c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]
                JuMP.set_lower_bound.(pcdcg[i][c], -_PM.ref(pm, nw, :convdc)[i]["Pacrated"][c] * bigM)
                JuMP.set_upper_bound.(pcdcg[i][c], _PM.ref(pm, nw, :convdc)[i]["Pacrated"][c] * bigM)
            end
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :pdcg, _PM.ids(pm, nw, :convdc), pcdcg)
end

"variable: `pconv_dcg_shunt[j]` for `j` in `convdc`"
function variable_dcside_grounding_shunt_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    pcdcg_shunt = _PM.var(pm, nw)[:pconv_dcg_shunt] = Dict(i => JuMP.@variable(pm.model,
        base_name = "$(nw)_pconv_dcg_shunt_$(i)",
        start = 0.0 #comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for i in _PM.ids(pm, nw, :convdc)
            JuMP.set_lower_bound.(pcdcg_shunt[i], -_PM.ref(pm, nw, :convdc)[i]["Pacrated"][1] * 0.1 * bigM * _PM.ref(pm, nw, :convdc)[i]["ground_type"])
            JuMP.set_upper_bound.(pcdcg_shunt[i], _PM.ref(pm, nw, :convdc)[i]["Pacrated"][1] * 0.1 * bigM * _PM.ref(pm, nw, :convdc)[i]["ground_type"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :pdcg_shunt, _PM.ids(pm, nw, :convdc), pcdcg_shunt)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    phic = _PM.var(pm, nw)[:phiconv] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_phiconv_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(phic[c], 0)
            JuMP.set_upper_bound.(phic[c], pi)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :phi, _PM.ids(pm, nw, :convdc), phic)
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    ic = _PM.var(pm, nw)[:iconv_ac] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_iconv_ac_$(i)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ic[c], 0)
            JuMP.set_upper_bound.(ic[c], convdc["Imax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv, _PM.ids(pm, nw, :convdc), ic)
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
    vmf = _PM.var(pm, nw)[:vmf] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_vmf_$(i)",
        start = 0 # start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vmf[c], convdc["Vmmin"] / bigM)
            JuMP.set_upper_bound.(vmf[c], convdc["Vmmax"] * bigM)
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :vmfilt, _PM.ids(pm, nw, :convdc), vmf)
end

"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #
    vaf = _PM.var(pm, nw)[:vaf] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_vaf_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vaf[c], -bigM)
            JuMP.set_upper_bound.(vaf[c], bigM)
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :vafilt, _PM.ids(pm, nw, :convdc), vaf)
end

function variable_converter_internal_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vmc = _PM.var(pm, nw)[:vmc] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_vmc_$(i)",
        start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vmc[c], convdc["Vmmin"])
            JuMP.set_upper_bound.(vmc[c], convdc["Vmmax"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :vmconv, _PM.ids(pm, nw, :convdc), vmc)
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #
    vac = _PM.var(pm, nw)[:vac] = Dict(i => JuMP.@variable(pm.model,
        [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name = "$(nw)_vac_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vac[c], -bigM)
            JuMP.set_upper_bound.(vac[c], bigM)
        end
    end
    report && _PM.sol_component_value(pm, nw, :convdc, :vaconv, _PM.ids(pm, nw, :convdc), vac)
end
