export run_mcdcopf

""
function run_mcdcopf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return run_mcdcopf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_mcdcopf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_mcdcopf; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function post_mcdcopf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)

    variable_mc_active_dcbranch_flow(pm)
    variable_mcdcgrid_voltage_magnitude(pm)
    variable_dcbranch_current(pm)
    variable_mcdc_converter(pm)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        display("Now it is callig dc grid kcl for bus $i")
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        display("Now it is callig all converter constraints")
        constraint_converter_losses(pm, i)
        constraint_converter_dc_ground(pm, i)
        constraint_converter_current(pm, i)
         constraint_converter_dc_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        display("end of constraints for converter $i")
        if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
    constraint_converter_dc_ground_shunt_kcl(pm)
end
