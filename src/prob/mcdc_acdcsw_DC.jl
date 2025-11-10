# DC Busbar splitting for AC/DC grid
"ACDC opf with controllable switches in DC busbar splitting configuration for AC/DC grids"
function run_acdcsw_DC(file, model_constructor, optimizer; kwargs...)
    return _PM.solve_model(file, model_constructor, optimizer, build_acdcsw_DC; ref_extensions=[add_ref_dcgrid_dcswitch!,_PM.ref_add_on_off_va_bounds!], kwargs...)
end

""
function build_acdcsw_DC(pm::_PM.AbstractPowerModel)
    # AC grid
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)

    # DC grid
    #_PMTP.variable_dc_switch_indicator(pm) # binary variable to indicate the status of a dc switch
    #_PMTP.variable_dc_switch_power(pm) # variable to indicate the power flowing through a dc switch (if closed)

    # DC grid
    #variable_mc_active_dcbranch_flow_sw(pm, bounded=true)
    #variable_mc_dcbranch_current(pm, bounded=true)
    #variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    #variable_mcdc_converter(pm, bounded=true)

    #=
    # Objective function
    _PMTP.objective_min_fuel_cost_dc_switch(pm)

    # Constraints
    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt_sw(pm, i)
    end

    for i in _PM.ids(pm, :dcswitch)
        _PMTP.constraint_dc_switch_thermal_limit(pm, i) # limiting the apparent power flowing through a dc switch
        _PMTP.constraint_dc_switch_power_on_off(pm,i)  # limiting the maximum active power through a dc switch
        _PMTP.constraint_dc_switch_voltage_on_off_big_M(pm, i)
    end

    for i in _PM.ids(pm, :dcswitch_couples)
        _PMTP.constraint_exclusivity_dc_switch(pm, i) # the sum of the switches in a couple must be lower or equal than one (if OTS is allowed, like here), as each grid element is connected to either part of a split busbar no matter if the ZIL switch is opened or closed
        _PMTP.constraint_BS_OTS_dcbranch(pm, i) # making sure that if the grid element is not reconnected to the split busbar, the active and reactive power flowing through the switch is 0
        _PMTP.constraint_ZIL_dc_switch(pm,i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc_switch(pm, i) # taking into account dc switches in the power balance of the dc part of an AC/DC grid
    end
    for i in _PM.ids(pm, :branchdc)
        _PMACDC.constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        _PMACDC.constraint_converter_losses(pm, i)
        _PMACDC.constraint_converter_current(pm, i)
        _PMACDC.constraint_conv_transformer(pm, i)
        _PMACDC.constraint_conv_reactor(pm, i)
        _PMACDC.constraint_conv_filter(pm, i)
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            _PMACDC.constraint_conv_firing_angle(pm, i)
        end
    end
    =#
end