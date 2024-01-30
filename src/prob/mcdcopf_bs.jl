export solve_mcdcopf_bs

import PowerModels as _PM
import PowerModelsTopologicalActionsII as _PMTP
import PowerModelsACDC as _PMACDC

"""
Implementing AC busbar splitting here
"""

function solve_mcdcopf_ac_bs(data::Dict{String,Any}, model_type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_mcdcopf_ac_bs; ref_extensions=[add_ref_dcgrid_switches_unbalanced!,_PM.ref_add_on_off_va_bounds!], kwargs...)
end

function build_mcdcopf_ac_bs(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    variable_mc_active_dcbranch_flow(pm, bounded=true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    variable_mcdc_converter(pm, bounded=true)

    variable_mc_dcbranch_current(pm, bounded=true)

    _PMTP.variable_switch_indicator(pm) # binary variable to indicate the status of an ac switch 
    _PMTP.variable_switch_power(pm) # variable to indicate the power flowing through an ac switch (if closed)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt_bs(pm, i)
    end

    for i in _PM.ids(pm, :switch)
        _PMTP.constraint_switch_thermal_limit(pm, i) # limiting the apparent power flowing through an ac switch
        _PMTP.constraint_switch_voltage_on_off(pm,i) # making sure that the voltage magnitude and angles are equal at the two extremes of a closed switch
        _PMTP.constraint_switch_power_on_off(pm,i) # limiting the maximum active and reactive power through an ac switch
        #_PMTP.constraint_switch_difference_voltage_angles(pm,i)
    end
    
    for i in _PM.ids(pm, :switch_couples)
        _PMTP.constraint_exclusivity_switch(pm, i) # the sum of the switches in a couple must be lower or equal than one (if OTS is allowed, like here), as each grid element is connected to either part of a split busbar no matter if the ZIL switch is opened or closed
        _PMTP.constraint_BS_OTS_branch(pm,i) # making sure that if the grid element is not reconnected to the split busbar, the active and reactive power flowing through the switch is 0
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_converter_dc_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
    constraint_converter_dc_ground_shunt_ohm(pm)
end

"""
Implementing DC busbar splitting here
"""
function solve_mcdcopf_dc_bs(data::Dict{String,Any}, model_type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_mcdcopf_dc_bs; ref_extensions=[add_ref_dcgrid_switches_unbalanced!,_PM.ref_add_on_off_va_bounds!], kwargs...)
end

function build_mcdcopf_dc_bs(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    variable_mc_active_dcbranch_flow(pm, bounded=true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    variable_mcdc_converter(pm, bounded=true)

    variable_mc_dcbranch_current(pm, bounded=true)

    _PMTP.variable_dc_switch_indicator(pm) # binary variable to indicate the status of a dc switch
    _PMTP.variable_dc_switch_power(pm) # variable to indicate the power flowing through a dc switch (if closed)


    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt_bs(pm, i)
    end

    for i in _PM.ids(pm, :dcswitch)
        _PMTP.constraint_dc_switch_thermal_limit(pm, i) # limiting the apparent power flowing through a dc switch
        _PMTP.constraint_dc_switch_voltage_on_off(pm,i) # making sure that the voltage magnituds are equal at the two extremes of a closed switch
        _PMTP.constraint_dc_switch_power_on_off(pm,i)  # limiting the maximum active power through a dc switch
    end
    
    for i in _PM.ids(pm, :dcswitch_couples)
        _PMTP.constraint_exclusivity_dc_switch(pm, i) # the sum of the switches in a couple must be lower or equal than one (if OTS is allowed, like here), as each grid element is connected to either part of a split busbar no matter if the ZIL switch is opened or closed
        _PMTP.constraint_BS_OTS_dcbranch(pm, i) # making sure that if the grid element is not reconnected to the split busbar, the active and reactive power flowing through the switch is 0
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i) # Problem here -> current of the dc switch to be included in the formulation
    end
    for i in _PM.ids(pm, :branchdc)
        _PMACDC.constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_converter_dc_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
    constraint_converter_dc_ground_shunt_ohm(pm)
end