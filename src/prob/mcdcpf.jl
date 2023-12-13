export solve_mcdcpf

""
function solve_mcdcpf(file::String, model_type::Type, solver; kwargs...)
    data = parse_file(file)
    return solve_mcdcpf(data, model_type, solver; ref_extensions=[add_ref_dcgrid!], kwargs...)
end

""
function solve_mcdcpf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.solve_model(data, model_type, solver, build_mcdcpf; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function build_mcdcpf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_gen_power(pm, bounded = false)
    _PM.variable_branch_power(pm, bounded = false)

    variable_mcdc_converter(pm, bounded = false)
    variable_mcdcgrid_voltage_magnitude(pm, bounded = false)
    variable_mc_dcbranch_current(pm, bounded = false)

    # _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)

    for (i,bus) in _PM.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)
    end


    for (i, bus) in _PM.ref(pm, :bus)
        # @show "KCL for bus $i"
        constraint_kcl_shunt(pm, i)
        # PV Bus Constraints
        if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm, i)
            for j in _PM.ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end
        end
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        # _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        # _PM.constraint_thermal_limit_from(pm, i)
        # _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    # for c in _PM.ids(pm, :convdc)
    for (c, conv) in _PM.ref(pm, :convdc)

        if conv["type_dc"] == 1 "dc_type =2: Vdc control"
            constraint_active_conv_setpoint(pm, c)
        elseif conv["type_dc"] == 2
            constraint_dc_voltage_magnitude_setpoint(pm, c)
        elseif conv["type_dc"] == 3
            constraint_dc_droop_control(pm, c)
        end

        if conv["type_ac"] == 1  "AC_type =1, Q control; 2= Vac control" 
            constraint_reactive_conv_setpoint(pm, c)
        elseif conv["type_ac"] == 2
            constraint_ac_voltage_setpoint(pm, c)
        elseif conv["type_ac"] == 3
            constraint_ac_droop_control(pm, c)
        end

        constraint_converter_losses(pm, c)
        # constraint_converter_dc_ground(pm, c) #important remove
        constraint_converter_current(pm, c)
        constraint_converter_dc_current(pm, c)
        constraint_conv_transformer(pm, c)
        constraint_conv_reactor(pm, c)
        constraint_conv_filter(pm, c)
        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][c]["islcc"] == 1
            constraint_conv_firing_angle(pm, c)
        end
    end
    constraint_converter_dc_ground_shunt_ohm(pm)
end
