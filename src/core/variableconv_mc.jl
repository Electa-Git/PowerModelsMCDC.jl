"All converter variables"
function variable_mcdc_converter(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_tranformer_flow(pm; kwargs...)
    variable_conv_reactor_flow(pm; kwargs...)

    variable_converter_active_power(pm; kwargs...)
    variable_converter_reactive_power(pm; kwargs...)
    variable_acside_current(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
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
function variable_converter_active_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    pc = _PM.var(pm, nw)[:pconv_ac] =  Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_ac_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # vdcm = _PM.var(pm, nw)[:vdcm] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :busdc)[i]["conductors"]], base_name="$(nw)_vdcm_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :busdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(pc[c],  convdc["Pacmin"])
            JuMP.set_upper_bound.(pc[c],  convdc["Pacmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :pconv, _PM.ids(pm, nw, :convdc), pc)
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    qc = _PM.var(pm, nw)[:qconv_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_qconv_ac_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pc = _PM.var(pm, nw)[:pconv_ac] =  Dict(i =>JuMP.@variable(pm.model,
    # [c in _PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_ac_$(i)",
    # start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qc[c],  convdc["Qacmin"])
            JuMP.set_upper_bound.(qc[c],  convdc["Qacmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :qconv, _PM.ids(pm, nw, :convdc), qc)
end


"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = false, report::Bool=true)
    bigM = 2;

    # display(_PM.ref(pm, nw, :convdc, 2))
    # display(_PM.ref(pm, nw, :convdc)[2]["conductors"])
    ptfto = _PM.var(pm, nw)[:pconv_tf_to] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_tf_to_$(i)",
    # start= 1.0
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c,  1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

   #  p = _PM.var(pm, nw)[:p_dcgrid] = Dict((l,i,j) =>JuMP.@variable(pm.model,
   #     [c in 1:_PM.ref(pm, nw, :branchdc, l)["conductors"]], base_name="$(nw)_pdcgrid_$((l,i,j))",
   #     start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", c, 0.0),
   #     ) for (l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)
   # )
   # vdcm = _PM.var(pm, nw)[:vdcm] = Dict(i =>JuMP.@variable(pm.model,
   # [c in 1:_PM.ref(pm, nw, :busdc)[i]["conductors"]], base_name="$(nw)_vdcm_$(i)",
   # start = comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", c, 1.0)
   # ) for i in _PM.ids(pm, nw, :busdc)
   # )
    println("ptfto for all")
    display(ptfto)

    println("ptfto for conv 1")
    display(ptfto[1])
    display(_PM.ref(pm, nw, :convdc)[1]["Pacrated"])


    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ptfto[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(ptfto[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :ptf_to, _PM.ids(pm, nw, :convdc), ptfto)
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qtfto = _PM.var(pm, nw)[:qconv_tf_to] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_qconv_tf_to__$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    println("qtfto for all")
    display(qtfto)

    println("ptfto for conv 1")
    display(qtfto[1])
    display(_PM.ref(pm, nw, :convdc)[1]["Qacrated"])

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            display(qtfto[c])
            display(-convdc["Qacrated"])
            JuMP.set_lower_bound.(qtfto[1],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qtfto[c],   convdc["Qacrated"] * bigM)
            # JuMP.set_lower_bound.(ptfto[c],  -convdc["Pacrated"] * bigM)
            # JuMP.set_upper_bound.(ptfto[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :qtf_to, _PM.ids(pm, nw, :convdc), qtfto)
end


"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )


    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(pprfr[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(pprfr[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :ppr_fr, _PM.ids(pm, nw, :convdc), pprfr)
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qprfr = _PM.var(pm, nw)[:qconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_qconv_pr_fr_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qprfr[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qprfr[c],   convdc["Qacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :qpr_fr, _PM.ids(pm, nw, :convdc), qprfr)
end

"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    ptffr = _PM.var(pm, nw)[:pconv_tf_fr] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_tf_fr_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ptffr[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(ptffr[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :pgrid, _PM.ids(pm, nw, :convdc), ptffr)
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qtffr = _PM.var(pm, nw)[:qconv_tf_fr] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_qconv_tf_fr_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "Q_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )


    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(qtffr[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound.(qtffr[c],   convdc["Qacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :qgrid, _PM.ids(pm, nw, :convdc), qtffr)
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    pcdc = _PM.var(pm, nw)[:pconv_dc] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_dc_$(i)",
    start = 1.0 #comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(pcdc[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound.(pcdc[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :pdc, _PM.ids(pm, nw, :convdc), pcdc)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    phic = _PM.var(pm, nw)[:phiconv] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_phiconv_$(i)",
    start = 0
    # start = acos(comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pdcset", c, 1.0) / sqrt((comp_start_value(_PM.ref(pm, nw, :convdc, i), "Pacrated", 1.0))^2 + (comp_start_value(_PM.ref(pm, nw, :convdc, i), "Qacrated", c, 1.0))^2))
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(phic[c],  0)
            JuMP.set_upper_bound.(phic[c],  pi)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :phi, _PM.ids(pm, nw, :convdc), phic)
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic = _PM.var(pm, nw)[:iconv_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_iconv_ac_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ic[c],  0)
            JuMP.set_upper_bound.(ic[c],  convdc["Imax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :iconv, _PM.ids(pm, nw, :convdc), ic)
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic = _PM.var(pm, nw)[:iconv_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_iconv_ac_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    icsq = _PM.var(pm, nw)[:iconv_ac_sq] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_iconv_ac_sq_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(ic[c],  0)
            JuMP.set_upper_bound.(ic[c],  convdc["Imax"])
            JuMP.set_lower_bound.(icsq[c],  0)
            JuMP.set_upper_bound.(icsq[c],  convdc["Imax"]^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :iconv_ac, _PM.ids(pm, nw, :convdc), ic)
    report && _IM.sol_component_value(pm, nw, :convdc, :iconv_ac_sq, _PM.ids(pm, nw, :convdc), icsq)
end

"variable: `itf_sq[j]` for `j` in `convdc`"
function variable_conv_transformer_current_sqr(pm::_PM.AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2; #TODO derive exact bound
    itfsq = _PM.var(pm, nw)[:itf_sq] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_itf_sq_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(itfsq[c],  0)
            JuMP.set_upper_bound(itfsq[c], (bigM * convdc["Imax"])^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :itf_sq, _PM.ids(pm, nw, :convdc), itfsq)
end


"variable: `irc_sq[j]` for `j` in `convdc`"
function variable_conv_reactor_current_sqr(pm::_PM.AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2; #TODO derive exact bound
    iprsq = _PM.var(pm, nw)[:irc_sq] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_irc_sq_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(iprsq[c],  0)
            JuMP.set_upper_bound.(iprsq[c], (bigM * convdc["Imax"])^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :ipr_sq, _PM.ids(pm, nw, :convdc), iprsq)
end


function variable_converter_filter_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end


"variable: `vmf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    vmf = _PM.var(pm, nw)[:vmf] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_vmf_$(i)",
    start=0 # start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vmf[c], convdc["Vmmin"] / bigM)
            JuMP.set_upper_bound.(vmf[c], convdc["Vmmax"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :vmfilt, _PM.ids(pm, nw, :convdc), vmf)
end


"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vaf = _PM.var(pm, nw)[:vaf] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_vaf_$(i)",
    start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vaf[c], -bigM)
            JuMP.set_upper_bound.(vaf[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :vafilt, _PM.ids(pm, nw, :convdc), vaf)
end


function variable_converter_internal_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end


"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vmc = _PM.var(pm, nw)[:vmc] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_vmc_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")
    ) for i in _PM.ids(pm, nw, :convdc)
    )

    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vmc[c], convdc["Vmmin"])
            JuMP.set_upper_bound.(vmc[c], convdc["Vmmax"])
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :vmconv, _PM.ids(pm, nw, :convdc), vmc)
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vac = _PM.var(pm, nw)[:vac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_vac_$(i)",
    start = 0
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(vac[c], -bigM)
            JuMP.set_upper_bound.(vac[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :vaconv, _PM.ids(pm, nw, :convdc), vac)
end



"variable: `wrf_ac[j]` and `wif_ac`  for `j` in `convdc`"
function variable_converter_filter_voltage_cross_products(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrfac = _PM.var(pm, nw)[:wrf_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wrf_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    wifac = _PM.var(pm, nw)[:wif_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wif_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(wrfac[c],  0)
            JuMP.set_upper_bound.(wrfac[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound.(wifac[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound.(wifac[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :wrfilt, _PM.ids(pm, nw, :convdc), wrfac)
    report && _IM.sol_component_value(pm, nw, :convdc, :wifilt, _PM.ids(pm, nw, :convdc), wifac)
end

"variable: `wf_ac` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wfac = _PM.var(pm, nw)[:wf_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wf_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(wfac[c], (convdc["Vmmin"] / bigM)^2)
            JuMP.set_upper_bound.(wfac[c], (convdc["Vmmax"] * bigM)^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :wfilt, _PM.ids(pm, nw, :convdc), wfac)
end


"variable: `wrc_ac[j]` and `wic_ac[j]`  for `j` in `convdc`"
function variable_converter_internal_voltage_cross_products(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrcac = _PM.var(pm, nw)[:wrc_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wrc_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )

    wicac = _PM.var(pm, nw)[:wic_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wic_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(wrcac[c],  0)
            JuMP.set_upper_bound.(wrcac[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound.(wicac[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound.(wicac[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :wrconv, _PM.ids(pm, nw, :convdc), wrcac)
    report && _IM.sol_component_value(pm, nw, :convdc, :wiconv, _PM.ids(pm, nw, :convdc), wicac)
end

"variable: `wc_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wcac = _PM.var(pm, nw)[:wc_ac] = Dict(i =>JuMP.@variable(pm.model,
    [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_wc_ac_$(i)",
    start = _PM.ref(pm, nw, :convdc, i, "Vtar")^2
    ) for i in _PM.ids(pm, nw, :convdc)
    )
    # pprfr = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(i =>JuMP.@variable(pm.model,
    # [c in 1:_PM.ref(pm, nw, :convdc)[i]["conductors"]], base_name="$(nw)_pconv_pr_fr_$(i)",
    # start = comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", c, 1.0)
    # ) for i in _PM.ids(pm, nw, :convdc)
    # )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound.(wcac[c], (convdc["Vmmin"])^2)
            JuMP.set_upper_bound.(wcac[c], (convdc["Vmmax"])^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc, :wconv, _PM.ids(pm, nw, :convdc), wcac)
end

function variable_cos_voltage(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    #only for lpac
end



##################################### TNEP variables ##################################
"All converter variables"
function variable_dc_converter_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_tranformer_flow_ne(pm; kwargs...)
    variable_conv_reactor_flow_ne(pm; kwargs...)
    variable_converter_ne(pm; kwargs...)

    variable_converter_active_power_ne(pm; kwargs...)
    variable_converter_reactive_power_ne(pm; kwargs...)
    variable_acside_current_ne(pm; kwargs...)
    variable_dcside_power_ne(pm; kwargs...)
    # variable_converter_firing_angle_ne(pm; kwargs...)

    variable_converter_filter_voltage_ne(pm; kwargs...)
    variable_converter_internal_voltage_ne(pm; kwargs...)
    #
    variable_converter_to_grid_active_power_ne(pm; kwargs...)
    variable_converter_to_grid_reactive_power_ne(pm; kwargs...)
end

function variable_conv_tranformer_flow_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_transformer_active_power_to_ne(pm; kwargs...)
    variable_conv_transformer_reactive_power_to_ne(pm; kwargs...)
end

function variable_conv_reactor_flow_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_reactor_active_power_from_ne(pm; kwargs...)
    variable_conv_reactor_reactive_power_from_ne(pm; kwargs...)
end


"variable: `0 <= convdc_ne[c] <= 1` for `c` in `candidate converters"
function variable_converter_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        Z_dc_conv_ne = _PM.var(pm, nw)[:conv_ne] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_conv_ne",
        binary = true,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "branchdc_tnep_start", 1.0)
        )
    else
        Z_dc_conv_ne = _PM.var(pm, nw)[:conv_ne] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_conv_ne",
        lower_bound = 0,
        upper_bound = 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "branchdc_tnep_start", 1.0)
        )
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :isbuilt, _PM.ids(pm, nw, :convdc_ne), Z_dc_conv_ne)
 end

"variable: `pconv_ac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_active_power_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    pc_ne = _PM.var(pm, nw)[:pconv_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_pconv_ac_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(pc_ne[c],  convdc["Pacmin"])
            JuMP.set_upper_bound(pc_ne[c],  convdc["Pacmax"])
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :pconv, _PM.ids(pm, nw, :convdc_ne), pc_ne)
 end

"variable: `qconv_ac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_reactive_power_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    qc_ne =  _PM.var(pm, nw)[:qconv_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_qconv_ac_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Q_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(qc_ne[c],  convdc["Qacmin"])
            JuMP.set_upper_bound(qc_ne[c],  convdc["Qacmax"])
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :qconv, _PM.ids(pm, nw, :convdc_ne), qc_ne)
end


"variable: `pconv_grid_ac_to_ne[j]` for `j` in `candidate convdc`"
function variable_conv_transformer_active_power_to_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    ptfto_ne = _PM.var(pm, nw)[:pconv_tf_to_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_pconv_tf_to_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(ptfto_ne[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(ptfto_ne[c],   convdc["Pacrated"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :ptf_to, _PM.ids(pm, nw, :convdc_ne), ptfto_ne)
 end

"variable: `qconv_grid_ac_to_ne[j]` for `j` in `candidate convdc`"
function variable_conv_transformer_reactive_power_to_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qtfto_ne = _PM.var(pm, nw)[:qconv_tf_to_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_qconv_tf_to_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Q_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(qtfto_ne[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound(qtfto_ne[c],   convdc["Qacrated"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :qtf_to, _PM.ids(pm, nw, :convdc_ne), qtfto_ne)
end


"variable: `pconv_pr_from_ne[j]` for `j` in `candidate convdc`"
function variable_conv_reactor_active_power_from_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2
    pprfr_ne = _PM.var(pm, nw)[:pconv_pr_fr_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_pconv_pr_from_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(pprfr_ne[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(pprfr_ne[c],   convdc["Pacrated"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :ppr_fr, _PM.ids(pm, nw, :convdc_ne), pprfr_ne)
end

"variable: `qconv_pr_from_ne[j]` for `j` in `candidate convdc`"
function variable_conv_reactor_reactive_power_from_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2
    qprfr_ne = _PM.var(pm, nw)[:qconv_pr_fr_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_qconv_pr_from_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Q_g", 1.0)
    )
    if bounded
       for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
           JuMP.set_lower_bound(qprfr_ne[c],  -convdc["Qacrated"] * bigM)
           JuMP.set_upper_bound(qprfr_ne[c],   convdc["Qacrated"] * bigM)
       end
   end
   report && _IM.sol_component_value(pm, nw, :convdc_ne, :qpr_fr, _PM.ids(pm, nw, :convdc_ne), qprfr_ne)
end


"variable: `pconv_grid_ac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_to_grid_active_power_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2
    ptffr_ne = _PM.var(pm, nw)[:pconv_tf_fr_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_pconv_tf_fr_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
       for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
           JuMP.set_lower_bound(ptffr_ne[c],  -convdc["Pacrated"] * bigM)
           JuMP.set_upper_bound(ptffr_ne[c],   convdc["Pacrated"] * bigM)
       end
   end
   report && _IM.sol_component_value(pm, nw, :convdc_ne, :pgrid, _PM.ids(pm, nw, :convdc_ne), ptffr_ne)
end

"variable: `qconv_grid_ac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_to_grid_reactive_power_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2
    qtffr_ne = _PM.var(pm, nw)[:qconv_tf_fr_ne] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_qconv_tf_fr_ne",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Q_g", 1.0)
        )
        if bounded
           for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
               JuMP.set_lower_bound(qtffr_ne[c],  -convdc["Qacrated"] * bigM)
               JuMP.set_upper_bound(qtffr_ne[c],   convdc["Qacrated"] * bigM)
           end
       end
       report && _IM.sol_component_value(pm, nw, :convdc_ne, :qgrid, _PM.ids(pm, nw, :convdc_ne), qtffr_ne)
end


"variable: `pconv_dc_ne[j]` for `j` in `candidate convdc`"
function variable_dcside_power_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    pcdc_ne = _PM.var(pm, nw)[:pconv_dc_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_pconv_dc_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Pdcset", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(pcdc_ne[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(pcdc_ne[c],   convdc["Pacrated"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :pdc, _PM.ids(pm, nw, :convdc_ne), pcdc_ne)
 end

"variable: `pconv_dc_ne[j]` for `j` in `candidate convdc`"
function variable_converter_firing_angle_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    phic_ne = _PM.var(pm, nw)[:phiconv_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_phiconv",
    lower_bound = 0,
    upper_bound =  pi,
    start = acos(_PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Pdcset", 1.0) / sqrt((_PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Pacrated", 1.0))^2 + (_PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "Qacrated", 1.0))^2))
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(phic_ne[c],  0)
            JuMP.set_upper_bound(phic_ne[c],  pi)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :phi, _PM.ids(pm, nw, :convdc_ne), phic_ne)
end

"variable: `iconv_ac_ne[j]` for `j` in `candidate convdc`"
function variable_acside_current_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic_ne = _PM.var(pm, nw)[:iconv_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_iconv_ac_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(ic_ne[c],  0)
            JuMP.set_upper_bound(ic_ne[c],  convdc["Imax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc_ne, :iconv, _PM.ids(pm, nw, :convdc_ne), ic_ne)
 end

"variable: `iconv_ac_ne[j]` and `iconv_ac_sq_ne[j]` for `j` in `candidate convdc`"
function variable_acside_current_ne(pm::_PM.AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic_ne = _PM.var(pm, nw)[:iconv_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_iconv_ac_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    icsq_ne = _PM.var(pm, nw)[:iconv_ac_sq_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_iconv_ac_sq_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)
    )
    if bounded
    for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
        JuMP.set_lower_bound(ic_ne[c],  0)
        JuMP.set_upper_bound(ic_ne[c],  convdc["Imax"])
        JuMP.set_lower_bound(icsq_ne[c],  0)
        JuMP.set_upper_bound(icsq_ne[c],  convdc["Imax"]^2)
    end
end
report && _IM.sol_component_value(pm, nw, :convdc_ne, :iconv_ac, _PM.ids(pm, nw, :convdc_ne), ic_ne)
report && _IM.sol_component_value(pm, nw, :convdc_ne, :iconv_ac_sq, _PM.ids(pm, nw, :convdc_ne), icsq_ne)
end

"variable: `itf_sq_ne[j]` for `j` in `candidate convdc`"
function variable_conv_transformer_current_sqr_ne(pm::_PM.AbstractWModels;  nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2 #TODO derive exact bound
    itfsq_ne = _PM.var(pm, nw)[:itf_sq_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_itf_sq_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(itfsq_ne[c],  0)
            JuMP.set_upper_bound(itfsq_ne[c], (bigM * convdc["Imax"])^2)
        end
    end
report && _IM.sol_component_value(pm, nw, :convdc_ne, :itf_sq, _PM.ids(pm, nw, :convdc_ne), itfsq_ne)
end


"variable: `irc_sq_ne[j]` for `j` in `candidate convdc`"
function variable_conv_reactor_current_sqr_ne(pm::_PM.AbstractWModels;  nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2 #TODO derive exact bound
    iprsq_ne = _PM.var(pm, nw)[:irc_sq_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_irc_sq_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "P_g", 1.0)^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(iprsq_ne[c],  0)
            JuMP.set_upper_bound(iprsq_ne[c], (bigM * convdc["Imax"])^2)
        end
    end
report && _IM.sol_component_value(pm, nw, :convdc_ne, :ipr_sq, _PM.ids(pm, nw, :convdc_ne), iprsq_ne)
end


function variable_converter_filter_voltage_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude_ne(pm; kwargs...)
    variable_converter_filter_voltage_angle_ne(pm; kwargs...)
end


"variable: `vmf_ne[j]` for `j` in `candidate convdc`"
function variable_converter_filter_voltage_magnitude_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    vmf_ne = _PM.var(pm, nw)[:vmf_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_vmf_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(vmf_ne[c], convdc["Vmmin"] / bigM)
            JuMP.set_upper_bound(vmf_ne[c], convdc["Vmmax"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :vmfilt, _PM.ids(pm, nw, :convdc_ne), vmf_ne)
end


"variable: `vaf_ne[j]` for `j` in `candidate convdc`"
function variable_converter_filter_voltage_angle_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vaf_ne = _PM.var(pm, nw)[:vaf_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_vaf_ne",
    start = 0
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(vaf_ne[c], -bigM)
            JuMP.set_upper_bound(vaf_ne[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :vafilt, _PM.ids(pm, nw, :convdc_ne), vaf_ne)
end


function variable_converter_internal_voltage_ne(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude_ne(pm; kwargs...)
    variable_converter_internal_voltage_angle_ne(pm; kwargs...)
end


"variable: `vmc_ne[j]` for `j` in `candidate convdc`"
function variable_converter_internal_voltage_magnitude_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vmc_ne = _PM.var(pm, nw)[:vmc_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_vmc_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vmc_ne[c], convdc["Vmmin"])
            JuMP.set_upper_bound(vmc_ne[c], convdc["Vmmax"])
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :vmconv, _PM.ids(pm, nw, :convdc_ne), vmc_ne)
end

"variable: `vac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_internal_voltage_angle_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vac_ne = _PM.var(pm, nw)[:vac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_vac_ne",
    start = 0
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(vac_ne[c], -bigM)
            JuMP.set_upper_bound(vac_ne[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :vaconv, _PM.ids(pm, nw, :convdc_ne), vac_ne)
end



"variable: `wrf_ac_ne[j]` and `wif_ac`  for `j` in `candidate convdc`"
function variable_converter_filter_voltage_cross_products_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrfac_ne = _PM.var(pm, nw)[:wrf_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wrf_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    wifac_ne = _PM.var(pm, nw)[:wif_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wif_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(wrfac_ne[c],  0)
            JuMP.set_upper_bound(wrfac_ne[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound(wifac_ne[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound(wifac_ne[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wrfilt, _PM.ids(pm, nw, :convdc_ne), wrfac_ne)
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wifilt, _PM.ids(pm, nw, :convdc_ne), wifac_ne)
end

"variable: `wf_ac_ne` for `j` in `candidate convdc`"
function variable_converter_filter_voltage_magnitude_sqr_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wfac_ne = _PM.var(pm, nw)[:wf_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wf_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(wfac_ne[c], 0) # check
            # JuMP.set_lower_bound(wfac_ne[c], (convdc["Vmmin"] / bigM)^2)
            JuMP.set_upper_bound(wfac_ne[c], (convdc["Vmmax"] * bigM)^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wfilt, _PM.ids(pm, nw, :convdc_ne), wfac_ne)
end


"variable: `wrc_ac_ne[j]` and `wic_ac_ne[j]`  for `j` in `candidate convdc`"
function variable_converter_internal_voltage_cross_products_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrcac_ne = _PM.var(pm, nw)[:wrc_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wrc_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    wicac_ne = _PM.var(pm, nw)[:wic_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wic_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(wrcac_ne[c],  0)
            JuMP.set_upper_bound(wrcac_ne[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound(wicac_ne[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound(wicac_ne[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wrconv, _PM.ids(pm, nw, :convdc_ne), wrcac_ne)
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wiconv, _PM.ids(pm, nw, :convdc_ne), wicac_ne)

end

"variable: `wc_ac_ne[j]` for `j` in `candidate convdc`"
function variable_converter_internal_voltage_magnitude_sqr_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wcac_ne = _PM.var(pm, nw)[:wc_ac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_wc_ac_ne",
    start = _PM.ref(pm, nw, :convdc_ne, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(wcac_ne[c], 0) # check
            # JuMP.set_lower_bound(wcac[c], (convdc["Vmmin"])^2)
            JuMP.set_upper_bound(wcac_ne[c], (convdc["Vmmax"])^2)
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wconv, _PM.ids(pm, nw, :convdc_ne), wcac_ne)
end

function variable_voltage_slack(pm::_PM.AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=false)
    w_du = _PM.var(pm, nw)[:w_du] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_w_du",
    start = 0,  # check
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc_ne)
            JuMP.set_lower_bound(w_du[c], 0) # check
            JuMP.set_upper_bound(w_du[c], 2) # check
        end
    end
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :wdu, _PM.ids(pm, nw, :convdc_ne), w_du)
end


function variable_cos_voltage_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    #only for lpac
end
