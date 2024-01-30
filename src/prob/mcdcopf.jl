export solve_mcdcopf

"""
    solve_mcdcopf(file, model_type, optimizer; <keyword arguments>)
    solve_mcdcopf(data, model_type, optimizer; <keyword arguments>)

Build and solve the OPF problem over a hybrid AC/DC network, using a multi-conductor model for the DC part.

Input can be a Matpower `file` or a `data` dictionary.
The OPF problem being built is the one defined in `build_mcdcopf`.
Keyword arguments, if any, are forwarded to `PowerModels.solve_model`.
"""
function solve_mcdcopf end

function solve_mcdcopf(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return solve_mcdcopf(data, model_type, optimizer; ref_extensions=[add_ref_dcgrid!], kwargs...)
end

function solve_mcdcopf(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_mcdcopf; ref_extensions=[add_ref_dcgrid!], kwargs...)
end

"""
    build_mcdcopf(pm::PowerModels.AbstractPowerModel)

Build the OPF problem over a hybrid AC/DC network, using a multi-conductor model for the DC part.

The objective is the minimization of generation cost.
"""
function build_mcdcopf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    variable_mc_active_dcbranch_flow(pm, bounded=true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    variable_mcdc_converter(pm, bounded=true)

    variable_mc_dcbranch_current(pm, bounded=true)


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
