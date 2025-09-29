# Testing the different formulations
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt
import Gurobi
import HiGHS

nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
gurobi = _PMMCDC.optimizer_with_attributes(Gurobi.Optimizer)

file = "$(dirname(@__DIR__))/test/data/case5_2grids_MC.m"


data = _PMMCDC.parse_file(file)

s = Dict("conv_losses_mp" => false)

result_ac = _PMMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, nlp_solver, setting = s)
result_lpac = _PMMCDC.solve_mcdcopf(data, _PM.LPACCPowerModel, nlp_solver, setting = s) # This to be checked
result_dc = _PMMCDC.solve_mcdcopf(data, _PM.DCPPowerModel, gurobi, setting = s)


function solve_mcdcopf_lpac(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_mcdcopf_lpac; ref_extensions=[_PMMCDC.add_ref_dcgrid!], kwargs...)
end



function build_mcdcopf_lpac(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    _PMMCDC.variable_mc_active_dcbranch_flow(pm, bounded=true)
    _PMMCDC.variable_mc_dcbranch_current(pm, bounded=true)
    _PMMCDC.variable_mcdcgrid_voltage_magnitude(pm, bounded=true)
    _PMMCDC.variable_mcdc_converter(pm, bounded=true)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end
    
    for i in _PM.ids(pm, :bus)
        _PMMCDC.constraint_kcl_shunt(pm, i)
    end
    
    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    
    for i in _PM.ids(pm, :busdc)
        _PMMCDC.constraint_kcl_shunt_dcgrid(pm, i)
    end

    for i in _PM.ids(pm, :branchdc)
        _PMMCDC.constraint_ohms_dc_branch(pm, i)
    end
    
    for i in _PM.ids(pm, :convdc)
        _PMMCDC.constraint_converter_losses(pm, i)
        _PMMCDC.constraint_converter_current(pm, i)
        _PMMCDC.constraint_converter_dc_current(pm, i)
        _PMMCDC.constraint_conv_transformer(pm, i)
        _PMMCDC.constraint_conv_reactor(pm, i)
        _PMMCDC.constraint_conv_filter(pm, i)

        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            _PMMCDC.constraint_conv_firing_angle(pm, i)
        end
    end
    _PMMCDC.constraint_converter_dc_ground_shunt_ohm(pm)
    
end

result_lpac_troubleshoot = solve_mcdcopf_lpac(data, _PM.LPACCPowerModel, nlp_solver, setting = s)

