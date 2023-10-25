export solve_mcdcpf_prev

""
function solve_mcdcpf_prev(file::String, model_type::Type, solver; kwargs...)
    data = parse_file(file)
    return solve_mcdcpf_prev(data, model_type, solver; ref_extensions=[add_ref_dcgrid!], kwargs...)
end

""
function solve_mcdcpf_prev(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.solve_model(data, model_type, solver, build_mcdcpf_prev; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function build_mcdcpf_prev(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = true)
    _PM.variable_gen_power(pm, bounded = true)
    _PM.variable_branch_power(pm, bounded = true)

    variable_mcdc_converter(pm, bounded = true)
    variable_mcdcgrid_voltage_magnitude(pm, bounded = true)
    variable_mc_dcbranch_current(pm, bounded = true)

    _PM.objective_min_fuel_cost(pm)

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
    # for c in _PM.ids(pm, :convdc)
    for (c, conv) in _PM.ref(pm, :convdc)
        # if conv["type_dc"] == 2
        #     constraint_dc_voltage_magnitude_setpoint(pm, c)
        #     constraint_reactive_conv_setpoint(pm, c)
        # else
        #     if conv["type_ac"] == 2
        #         constraint_active_conv_setpoint(pm, c)
        #     else
        #         constraint_active_conv_setpoint(pm, c)
        #         constraint_reactive_conv_setpoint(pm, c)
        #     end
        # end

        # if conv["type_dc"] == 2 "dc_type =2: Vdc control"
        #     if conv["type_ac"] == 1  "AC_type =1, Q control; 2= Vac control" 
        #         constraint_dc_voltage_magnitude_setpoint(pm, c)
        #         constraint_reactive_conv_setpoint(pm, c)
        #     elseif  conv["type_ac"] == 2
        #         constraint_dc_voltage_magnitude_setpoint(pm, c)
        #         # constraint_ac_voltage_setpoint(pm, c)
        #     else
        #         "for the droop==> future"
        #         constraint_dc_droop_control(pm, c)
        #     end

        # else "dc_type =1: Pdc control"
        #     if conv["type_ac"] == 1 "AC_type =1, Q control; 2= Vac control"
        #         constraint_active_conv_setpoint(pm, c)
        #         constraint_reactive_conv_setpoint(pm, c)
        #     else 
        #         constraint_active_conv_setpoint(pm, c)
        #         # constraint_ac_voltage_setpoint(pm, c)
        #     end
        # end

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
