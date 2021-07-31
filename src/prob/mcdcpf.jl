export run_mcdcpf

""
function run_mcdcpf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    # PowerModelsACDC.process_additional_data!(data)
    process_additional_data!(data)
    return run_mcdcpf(data::Dict{String,Any}, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_mcdcpf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_mcdcpf; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function post_mcdcpf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_gen_power(pm, bounded = false)
    _PM.variable_branch_power(pm, bounded = false)

    variable_mc_active_dcbranch_flow(pm, bounded = false)
    # variable_dcbranch_current(pm, bounded = false)
    variable_mcdc_converter(pm, bounded = false)
    variable_mcdcgrid_voltage_magnitude(pm, bounded = false)

    variable_mc_dcbranch_current(pm, bounded = true)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)

    # _PM.objective_min_fuel_cost(pm)

    for (i,bus) in _PM.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)
    end

    # for i in _PM.ids(pm, :bus) #
    for (i, bus) in _PM.ref(pm, :bus)
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
        if conv["type_dc"] == 2
            constraint_dc_voltage_magnitude_setpoint(pm, c)
            constraint_reactive_conv_setpoint(pm, c)
        else
            if conv["type_ac"] == 2
                constraint_active_conv_setpoint(pm, c)
            else
                constraint_active_conv_setpoint(pm, c)
                constraint_reactive_conv_setpoint(pm, c)
            end
        end

        constraint_converter_losses(pm, c)
        constraint_converter_dc_ground(pm, c)
        constraint_converter_current(pm, c)
        constraint_converter_dc_current(pm, c)
        constraint_conv_transformer(pm, c)
        constraint_conv_reactor(pm, c)
        constraint_conv_filter(pm, c)
        if pm.ref[:nw][pm.cnw][:convdc][c]["islcc"] == 1
            constraint_conv_firing_angle(pm, c)
        end
    end
    # constraint_converter_dc_ground_shunt_kcl(pm)
    constraint_converter_dc_ground_shunt_ohm(pm)

end

# function post_mcdcpf(pm::_PM.AbstractPowerModel)
#     _PM.variable_bus_voltage(pm, bounded = false)
#     _PM.variable_gen_power(pm, bounded = false)
#     _PM.variable_branch_power(pm, bounded = false)
#
#     # # dirty, should be improved in the future TODO
#     # if typeof(pm) <: _PM.SOCBFPowerModel
#     #     _PM.variable_branch_current(pm, bounded = false)
#     # end
#
#     variable_mc_active_dcbranch_flow(pm, bounded = false)
#     variable_dcbranch_current(pm, bounded = false)
#     variable_mcdc_converter(pm, bounded = false)
#     variable_mcdcgrid_voltage_magnitude(pm, bounded = false)
#
#     _PM.constraint_model_voltage(pm)
#     constraint_voltage_dc(pm)
#
#     # _PM.objective_min_fuel_cost(pm)
#
#     for (i,bus) in _PM.ref(pm, :ref_buses)
#         # @assert bus["bus_type"] == 3
#         _PM.constraint_theta_ref(pm, i)
#         # _PM.constraint_voltage_magnitude_setpoint(pm, i)
#     end
#
#     for (i, bus) in _PM.ref(pm, :bus)# _PM.ids(pm, :bus)
#         constraint_kcl_shunt(pm, i)
#         # PV Bus Constraints
#         if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))
#             # this assumes inactive generators are filtered out of bus_gens
#             # @assert bus["bus_type"] == 2
#             # _PM.constraint_voltage_magnitude_setpoint(pm, i)
#             for j in _PM.ref(pm, :bus_gens, i)
#                 # _PM.constraint_gen_setpoint_active(pm, j)
#             end
#         end
#     end
#
#     for i in _PM.ids(pm, :branch)
#         _PM.constraint_ohms_yt_from(pm, i)
#         _PM.constraint_ohms_yt_to(pm, i)
#         _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
#         _PM.constraint_thermal_limit_from(pm, i)
#         _PM.constraint_thermal_limit_to(pm, i)
#     end
#     for i in _PM.ids(pm, :busdc)
#         constraint_kcl_shunt_dcgrid(pm, i)
#     end
#     for i in _PM.ids(pm, :branchdc)
#         constraint_ohms_dc_branch(pm, i)
#     end
#     # for (c, conv) in _PM.ref(pm, :convdc)
#     for c in _PM.ids(pm, :convdc)
#         constraint_conv_transformer(pm, c)
#         constraint_conv_reactor(pm, c)
#         constraint_conv_filter(pm, c)
#         # if conv["type_dc"] == 2
#         #     constraint_dc_voltage_magnitude_setpoint(pm, c)
#         #     constraint_reactive_conv_setpoint(pm, c)
#         # else
#         #     if conv["type_ac"] == 2
#         #         constraint_active_conv_setpoint(pm, c)
#         #     else
#         #         constraint_active_conv_setpoint(pm, c)
#         #         constraint_reactive_conv_setpoint(pm, c)
#         #     end
#         # end
#         constraint_converter_losses(pm, c)
#         constraint_converter_current(pm, c)
#         constraint_converter_dc_ground(pm, c)
#         constraint_converter_dc_current(pm, c)
#     end
#     constraint_converter_dc_ground_shunt_kcl(pm)
#     constraint_converter_dc_ground_shunt_ohm(pm)
#
# end

# function post_mcdcpf(pm::_PM.AbstractPowerModel)
#     _PM.variable_bus_voltage(pm, bounded = true)
#     _PM.variable_gen_power(pm, bounded = true)
#     _PM.variable_branch_power(pm, bounded = true)
#
#     variable_mc_active_dcbranch_flow(pm, bounded = true)
#     variable_mcdcgrid_voltage_magnitude(pm, bounded = true)
#     variable_dcbranch_current(pm, bounded = true)
#     variable_mcdc_converter(pm, bounded = true)
#
#     _PM.objective_min_fuel_cost(pm)
#
#     _PM.constraint_model_voltage(pm)
#     constraint_voltage_dc(pm)
#
#     # for i in _PM.ids(pm, :ref_buses)
#     for (i,bus) in _PM.ref(pm, :ref_buses)
#         _PM.constraint_theta_ref(pm, i)
#     end
#
#
#     for (i,bus) in _PM.ref(pm, :bus)
#         constraint_kcl_shunt(pm, i)
#     end
#
#     for i in _PM.ids(pm, :branch)
#         _PM.constraint_ohms_yt_from(pm, i)
#         _PM.constraint_ohms_yt_to(pm, i)
#         _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
#         _PM.constraint_thermal_limit_from(pm, i)
#         _PM.constraint_thermal_limit_to(pm, i)
#     end
#     for i in _PM.ids(pm, :busdc)
#         display("Now it is callig dc grid kcl for bus $i")
#         constraint_kcl_shunt_dcgrid(pm, i)
#     end
#     for i in _PM.ids(pm, :branchdc)
#         constraint_ohms_dc_branch(pm, i)
#     end
#     for i in _PM.ids(pm, :convdc)
#         display("Now it is callig all converter constraints")
#         constraint_converter_losses(pm, i)
#         constraint_converter_dc_ground(pm, i)
#         constraint_converter_current(pm, i)
#          constraint_converter_dc_current(pm, i)
#         constraint_conv_transformer(pm, i)
#         constraint_conv_reactor(pm, i)
#         constraint_conv_filter(pm, i)
#         display("end of constraints for converter $i")
#         if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
#             constraint_conv_firing_angle(pm, i)
#         end
#     end
#     constraint_converter_dc_ground_shunt_kcl(pm)
#     constraint_converter_dc_ground_shunt_ohm(pm)
# end
