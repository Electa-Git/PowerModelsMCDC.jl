# DC Busbar splitting for AC/DC grid
"ACDC opf with controllable switches in DC busbar splitting configuration for AC/DC grids"
function solve_mcdc_acdcsw_DC(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, build_mcdc_acdcsw_DC; ref_extensions=[add_ref_dcgrid_dcswitch!,_PM.ref_add_on_off_va_bounds!], kwargs...)
end

""
function build_mcdc_acdcsw_DC(pm::_PM.AbstractPowerModel)
    # AC grid
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)

    # DC grid
    #_PMTP.variable_dc_switch_indicator(pm) # binary variable to indicate the status of a dc switch
    variable_dc_switch_current_mc(pm) # variable to indicate the power flowing through a dc switch (if closed)

    # DC grid
    variable_mc_active_dcbranch_flow(pm, bounded=true)
    variable_mc_dcbranch_current(pm, bounded=true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    variable_mcdc_converter(pm, bounded=true)

    
    # Objective function
    #_PMTP.objective_min_fuel_cost_dc_switch(pm)

    
    # Constraints
    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
    end

    # ADD HERE DISTINCTION FOR THE DIFFERENT CURRENTS
    for i in _PM.ids(pm, :dcswitch)
        constraint_dc_switch_thermal_limit_mc(pm, i) # limiting the apparent power flowing through a dc switch
        constraint_dc_switch_current_on_off_mc(pm,i)  # limiting the maximum active power through a dc switch
        constraint_dc_switch_voltage_on_off_big_M_mc(pm, i)
    end
    
    for i in _PM.ids(pm, :dcswitch_couples)
        constraint_exclusivity_dc_switch_mc(pm, i) # the sum of the switches in a couple must be lower or equal than one (if OTS is allowed, like here), as each grid element is connected to either part of a split busbar no matter if the ZIL switch is opened or closed
        constraint_BS_OTS_dcbranch_mc(pm, i) # making sure that if the grid element is not reconnected to the split busbar, the active and reactive power flowing through the switch is 0
        constraint_ZIL_dc_switch_mc(pm,i)
    end
    
    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    
    for i in _PM.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid_sw(pm, i) # taking into account dc switches in the power balance of the dc part of an AC/DC grid
    end
    
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end

    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_converter_dc_current_sw(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)

        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
    constraint_converter_dc_ground_shunt_ohm(pm)    
end

""

function solve_mcdcopf_fc_dc_bs(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_mcdcopf_fc_dc_bs; ref_extensions=[add_ref_dcgrid_dcswitch!,_PM.ref_add_on_off_va_bounds!], kwargs...)
end

function build_mcdcopf_fc_dc_bs(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    variable_mc_active_dcbranch_flow(pm, bounded=true)
    variable_mc_dcbranch_current(pm, bounded=true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    variable_mcdc_converter(pm, bounded=true)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end
    
    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt_fc(pm, i)
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
        constraint_converter_dc_current_sw(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)

        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
    constraint_converter_dc_ground_shunt_ohm(pm)
end