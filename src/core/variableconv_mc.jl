"All converter variables"
## Updated variables
function variable_conv_transformer_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_transformer_reactive_power_to(pm; kwargs...)
end


"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    
    bigM = 2
    #poles = _PM.ref(pm, nw, :conv_acpoles)
    vars = _PM.var(pm, nw)[:pconv_tf_to] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_pconv_tf_to_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_g", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],- bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :ptf_to, _PM.ids(pm, nw, :convdc), poles, vars)
end


"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    #poles = _PM.ref(pm, nw, :conv_acpoles)
    vars = _PM.var(pm, nw)[:qconv_tf_to] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_qconv_tf_to_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "Q_g", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],-bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :qtf_to, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_conv_reactor_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
    variable_conv_reactor_reactive_power_from(pm; kwargs...)
end

function variable_conv_reactor_active_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2

    vars = _PM.var(pm, nw)[:pconv_pr_fr] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_pconv_pr_fr_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_g", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],-bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :ppr_fr, _PM.ids(pm, nw, :convdc), poles, vars)

end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2

    vars = _PM.var(pm, nw)[:qconv_pr_fr] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_qconv_pr_fr_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "Q_g", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],-bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :qpr_fr, _PM.ids(pm, nw, :convdc), poles, vars)
end

function variable_mcdc_converter(pm::_PM.AbstractPowerModel; kwargs...)
    variable_conv_transformer_flow(pm; kwargs...)
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


"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_converter_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:pconv_ac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_pconv_ac_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_g", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Pacmin"][pole])
                    JuMP.set_upper_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Pacmax"][pole])
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :pconv, _PM.ids(pm, nw, :convdc), poles, vars)
end


"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:qconv_ac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_qconv_ac_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "Q_g", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Qacmin"][pole])
                    JuMP.set_upper_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Qacmax"][pole])
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :qconv, _PM.ids(pm, nw, :convdc), poles, vars)
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)

    vars = _PM.var(pm, nw)[:iconv_ac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_iconv_ac_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_ac_start", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],0)
                    JuMP.set_upper_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Imax"][pole])
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :iconv_ac, _PM.ids(pm, nw, :convdc), poles, vars)
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::_PM.AbstractWModels; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)

    vars = _PM.var(pm, nw)[:iconv_ac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_iconv_ac_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_ac_start", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    varssq = _PM.var(pm, nw)[:iconv_ac_sq] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_iconv_ac_sq_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_ac_start_sq", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(varssq[cv_id][pole],0)
                    JuMP.set_upper_bound.(varssq[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Imax"][pole])
                    JuMP.set_lower_bound.(varssq[cv_id][pole],0)
                    JuMP.set_upper_bound.(varssq[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Imax"][pole]^2)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :iconv_ac, _PM.ids(pm, nw, :convdc), poles, vars)

    report && sol_component_value_status(pm, nw, :convdc, :iconv_ac_sq, _PM.ids(pm, nw, :convdc), poles, vars)
end

function variable_dcside_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )
    for cv_id in keys(poles)
        push!(poles[cv_id],"r") # add grounding pole for current variable
    end

    vars = _PM.var(pm, nw)[:iconv_dc] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in poles[cv_id]], base_name = "$(nw)_iconv_dc_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_dc_start", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in poles[cv_id] #keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],- _PM.ref(pm, nw, :convdc, cv_id)["Imax"][first(poles[cv_id])]) # max current is same for all poles
                    JuMP.set_upper_bound.(vars[cv_id][pole],_PM.ref(pm, nw, :convdc, cv_id)["Imax"][first(poles[cv_id])])
                end
            end
        end
    end

    report && sol_component_value_status(pm, nw, :convdc, :iconv_dc, _PM.ids(pm, nw, :convdc), poles, vars)
end

function variable_dcside_current_ground(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:iconv_dcg] = Dict(cv_id => JuMP.@variable(pm.model,[pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_iconv_dcg_$(cv_id)",
        start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_dcg_start", pole, 1.0)
    ) for cv_id in _PM.ids(pm, nw, :convdc)
    )

    for cv_id in _PM.ids(pm, nw, :convdc)
        for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
            if bounded
                JuMP.set_lower_bound.(vars[cv_id], - (_PM.ref(pm, nw, :convdc, cv_id)["Imax"][pole]))
                JuMP.set_upper_bound.(vars[cv_id], _PM.ref(pm, nw, :convdc, cv_id)["Imax"][pole])
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for cv_id in _PM.ids(pm, nw, :convdc)
    )

    report && sol_component_value_status(pm, nw, :convdc, :iconv_dcg, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_dcside_current_grounding_shunt(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:iconv_dcg_shunt] = Dict(cv_id => JuMP.@variable(pm.model,
        base_name = "$(nw)_iconv_dcg_shunt_$(cv_id)",start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "I_conv_dcg_shunt_start", 0.0)
    ) for b_id in _PM.ids(pm, nw, :busdc_grounded_convs) for cv_id in keys(_PM.ref(pm, nw, :busdc_grounded_convs, b_id))
    )

    grounded_convs = Dict(
        cv_id => ["r"]
        for b_id in keys(pm.ref[:it][:pm][:nw][0][:busdc_grounded_convs]) for cv_id in keys(pm.ref[:it][:pm][:nw][0][:busdc_grounded_convs][b_id])
    )


        poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for cv_id in _PM.ids(pm, nw, :convdc)
    )

    if bounded
        for b_id in _PM.ids(pm, nw, :busdc_grounded_convs)
            for cv_id in keys(_PM.ref(pm, nw, :busdc_grounded_convs,b_id))            
                    JuMP.set_lower_bound(vars[cv_id], -(_PM.ref(pm, nw, :convdc, cv_id)["Imax"][first(poles[cv_id])]) * 0.1 * bigM)
                    JuMP.set_upper_bound(vars[cv_id], _PM.ref(pm, nw, :convdc, cv_id)["Imax"][first(poles[cv_id])] * 0.1 * bigM)
            end
        end
    end


    report && sol_component_value_status_grounding(pm, nw, :convdc, :iconv_dcg_shunt, keys(grounded_convs), grounded_convs, vars)
    #report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dcg_shunt, _PM.ids(pm, nw, :convdc), vars)
end



"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )
    for cv_id in keys(poles)
        push!(poles[cv_id],"r") # add grounding pole for current variable
    end
    
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:pconv_dc] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in poles[cv_id]], base_name = "$(nw)_pconv_dc_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_conv_dc_start", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])

    # There is the need to assign one Pacrated here, assuming the first value among the poles
    #first_pole = Dict(cv_id => first(poles[cv_id]) for cv_id in keys(poles))
    
    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in poles[cv_id] #keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],- (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][first(poles[cv_id])]* bigM))
                    JuMP.set_upper_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][first(poles[cv_id])]* bigM)
                end
            end
        end
    end

    #poles = Dict(
    #    cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
    #    for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    #)

    report && sol_component_value_status(pm, nw, :convdc, :pdc, _PM.ids(pm, nw, :convdc), poles, vars)

end

"variable: `pconv_dcg[j]` for `j` in `convdc`"
function variable_dcside_ground_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:pconv_dcg] = Dict(cv_id => JuMP.@variable(pm.model,[pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_pconv_dcg_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_conv_dcg_start", pole, 1.0)
    ) for cv_id in _PM.ids(pm, nw, :convdc)
    )

    for cv_id in _PM.ids(pm, nw, :convdc)
        for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
            if bounded
                JuMP.set_lower_bound.(vars[cv_id], - (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole])*bigM)
                JuMP.set_upper_bound.(vars[cv_id], _PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]*bigM)
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for cv_id in _PM.ids(pm, nw, :convdc)
    )

    report && sol_component_value_status(pm, nw, :convdc, :pdcg, _PM.ids(pm, nw, :convdc), poles, vars)
end

"variable: `pconv_dcg_shunt[j]` for `j` in `convdc`"
function variable_dcside_grounding_shunt_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # to account for losses, maximum losses to be derived
    vars = _PM.var(pm, nw)[:pconv_dcg_shunt] = Dict(cv_id => JuMP.@variable(pm.model,
        base_name = "$(nw)_pconv_dcg_shunt_$(cv_id)",start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_conv_dcg_shunt_start", 0.0)
    ) for b_id in _PM.ids(pm, nw, :busdc_grounded_convs) for cv_id in keys(_PM.ref(pm, nw, :busdc_grounded_convs, b_id))
    )

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for b_id in _PM.ids(pm, nw, :busdc_grounded_convs) for cv_id in keys(_PM.ref(pm, nw, :busdc_grounded_convs, b_id))
    )

    if bounded
        for b_id in _PM.ids(pm, nw, :busdc_grounded_convs)
            for cv_id in keys(_PM.ref(pm, nw, :busdc_grounded_convs,b_id))    
                
                    JuMP.set_lower_bound(vars[cv_id], -(_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][first(poles[cv_id])]) * 0.1 * bigM * _PM.ref(pm, nw, :convdc, cv_id)["ground_type"]) #Making sure there is a pole
                    JuMP.set_upper_bound(vars[cv_id], _PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][first(poles[cv_id])] * 0.1 * bigM * _PM.ref(pm, nw, :convdc, cv_id)["ground_type"])
            end
        end
    end


    report #&& sol_component_value_status(pm, nw, :convdc, :pdcg_shunt, _PM.ids(pm, nw, :convdc), poles, vars)
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)

    vars = _PM.var(pm, nw)[:phiconv] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_phiconv_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "phi_start_value", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],0)
                    JuMP.set_upper_bound.(vars[cv_id][pole],pi)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :phi, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_converter_filter_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end

"variable: `vmf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 1.2 # only internal converter voltage is strictly regulated

    vars = _PM.var(pm, nw)[:vmf] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_vmf_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "vmf_start_value", pole, 1.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmin"][pole] / bigM)
                    JuMP.set_upper_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmax"][pole] * bigM)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :vmfilt, _PM.ids(pm, nw, :convdc), poles, vars)
    
end

"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #

    vars = _PM.var(pm, nw)[:vaf] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_vaf_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "vaf_start_value", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole],- bigM)
                    JuMP.set_upper_bound.(vars[cv_id][pole],  bigM)
                end
            end
        end
    end


    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :vafilt, _PM.ids(pm, nw, :convdc), poles, vars)

end

function variable_converter_internal_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)

    vars = _PM.var(pm, nw)[:vmc] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_vmc_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "vmc_start_value", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmin"][pole])
                    JuMP.set_upper_bound.(vars[cv_id][pole], _PM.ref(pm, nw, :convdc, cv_id)["Vmmax"][pole])
                end
            end
        end
    end


    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :vmconv, _PM.ids(pm, nw, :convdc), poles, vars)
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #

    vars = _PM.var(pm, nw)[:vac] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_vac_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "vac_start_value", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole], -bigM)
                    JuMP.set_upper_bound.(vars[cv_id][pole],  bigM)
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :vaconv, _PM.ids(pm, nw, :convdc), poles, vars)
end


"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2

    vars = _PM.var(pm, nw)[:pconv_tf_fr] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_pconv_tf_fr_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "P_tf_fr", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole], - bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],  bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Pacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :pgrid, _PM.ids(pm, nw, :convdc), poles, vars)
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2
    vars = _PM.var(pm, nw)[:qconv_tf_fr] = Dict(cv_id => JuMP.@variable(pm.model,
    [pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])], base_name = "$(nw)_qconv_tf_fr_$(bus)_$(cv_id)",
    start = comp_start_value(_PM.ref(pm, nw, :convdc, cv_id), "Q_tf_fr", pole, 0.0)
    ) for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus])


    for bus in _PM.ids(pm, nw, :bus_conv_poles) 
        for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
            for pole in keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"])
                if bounded
                    JuMP.set_lower_bound.(vars[cv_id][pole], - bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                    JuMP.set_upper_bound.(vars[cv_id][pole],  bigM * (_PM.ref(pm, nw, :convdc, cv_id)["Qacrated"][pole]))
                end
            end
        end
    end

    poles = Dict(
        cv_id => collect(keys(_PM.ref(pm, nw, :convdc)[cv_id]["status"]))
        for bus in _PM.ids(pm, nw, :bus_conv_poles) for (cv_id,cv) in _PM.ref(pm, nw, :bus_conv_poles)[bus]
    )

    report && sol_component_value_status(pm, nw, :convdc, :qgrid, _PM.ids(pm, nw, :convdc), poles, vars)
end


function variable_converter_filter_voltage_angle_check(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    bigM = 2 * pi #
    #poles = _PM.ref(pm, nw, :conv_acpoles)
    vars = _PM.var(pm, nw)[:vaf_check] = Dict(i => JuMP.@variable(pm.model,
        [pole in keys(_PM.ref(pm, nw, :convdc)[i]["status"])], base_name = "$(nw)_vaf_check_$(i)",
        start = 0
    ) for i in _PM.ids(pm, nw, :convdc_poles)
    )

    for i in _PM.ids(pm, nw, :convdc_poles)
        for pole in keys(_PM.ref(pm, nw, :convdc)[i]["status"])
            if bounded
                JuMP.set_lower_bound.(vars[i][pole],- bigM)
                JuMP.set_upper_bound.(vars[i][pole],  bigM)
            end
        end
    end
    report #&& sol_component_value_status(pm, nw, :convdc, :vafilt, _PM.ids(pm, nw, :convdc), poles, vars)
end