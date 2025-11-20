# Testing the different formulations
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt
import Gurobi
import HiGHS
import Juniper
using PowerModelsTopologicalActionsII; const _PMTP = PowerModelsTopologicalActionsII


ipopt = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
gurobi = _PMMCDC.optimizer_with_attributes(Gurobi.Optimizer)
juniper = _PMMCDC.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => gurobi, "time_limit" => 36000)


file = "$(dirname(@__DIR__))/test/data/case5_2grids_MC.m"
results_folder = "/Users/giacomobastianel/Library/CloudStorage/OneDrive-KULeuven/Deliverable_1_2_DIRECTIONS/Results/PMMCDC"

data = _PMMCDC.parse_file(file)

s = Dict("conv_losses_mp" => false)

for (cv_id,cv) in data["convdc"]
    println([cv_id,cv["busdc_i"]])
end

result_ac = _PMMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt, setting = s)


function trying_model_dc_switch(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.instantiate_model(data, model_type, _PMMCDC.build_acdcsw_DC; ref_extensions=[_PMMCDC.add_ref_dcgrid_dcswitch!], kwargs...)
end

data_help = deepcopy(data)
data_help_ac_bs_base = deepcopy(data_help)
data_help_dc_bs_base = deepcopy(data_help)

for (cv_id,cv) in data_help_dc_bs_base["convdc"]
    n_poles = length(cv["Pacrated"]) 
    poles = keys(cv["Pacrated"])
    bus_dc_i_helper = deepcopy(cv["busdc_i"])
    cv["busdc_i"] = Dict{String,Any}()
    for p in poles
        cv["busdc_i"]["$p"] = deepcopy(bus_dc_i_helper)
    end
end

for (br_id,br) in data_help_dc_bs_base["branchdc"] 
    n_conductors = length(br["status"]) 
    conductors = keys(br["status"])
    fbusdc_helper = deepcopy(br["fbusdc"])
    tbusdc_helper = deepcopy(br["tbusdc"])
    br["fbusdc"] = Dict{String,Any}()
    br["tbusdc"] = Dict{String,Any}()
    for c in conductors
        br["fbusdc"]["$c"] = deepcopy(fbusdc_helper)
        br["tbusdc"]["$c"] = deepcopy(tbusdc_helper)
    end
end


for (cv_id,cv) in data_help["convdc"]
    n_poles = length(cv["Pacrated"]) 
    poles = keys(cv["Pacrated"])
    bus_ac_i_helper = deepcopy(cv["busac_i"])
    cv["busac_i"] = Dict{String,Any}()
    for p in poles
        cv["busac_i"]["$p"] = deepcopy(bus_ac_i_helper)
    end
end


splitted_bus_ac = 2
data_help_ac_bs,  switches_couples_ac,  extremes_ZILs_ac  = _PMTP.AC_busbars_split_multiconductor(data_help_ac_bs_base,splitted_bus_ac)

splitted_bus_dc = 4
data_help_dc_bs,  switches_couples_dc,  extremes_ZILs_dc  = _PMTP.DC_busbars_split_multiconductor(data_help,splitted_bus_dc)


for (sw_id,sw) in data_help_dc_bs["dcswitch"]
    println("-----")
    println("Switch $sw_id info:")
    if haskey(sw, "auxiliary")
        println("Switch $sw_id, from bus: $(sw["f_busdc"]), to bus: $(sw["t_busdc"]), auxiliary: $(sw["auxiliary"]), original $(sw["original"]), terminal: $(sw["terminal"])")
    else
        println("Switch $sw_id, from bus: $(sw["f_busdc"]), to bus: $(sw["t_busdc"]), terminal: $(sw["terminal"])")
    end
end

data_help_dc_bs_base["dcswitch"] = Dict{String,Any}()
diocane = trying_model_dc_switch(data_help_dc_bs, _PM.ACPPowerModel, ipopt)

diocane.var[:it][:pm][:nw][0][:z_dcswitch]