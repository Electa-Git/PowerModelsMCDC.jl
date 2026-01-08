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
    return _PM.instantiate_model(data, model_type, _PMMCDC.build_mcdc_acdcsw_DC; ref_extensions=[_PMMCDC.add_ref_dcgrid_dcswitch!], kwargs...)
end


data_help = deepcopy(data)
data_help_updated = deepcopy(data)
data_help_dc_bs_base = deepcopy(data_help)

splitted_bus_dc = 4
data_help_dc_bs,  switches_couples_dc,  extremes_ZILs_dc  = _PMTP.DC_busbars_split_multiconductor(data_help,splitted_bus_dc)
data_help_dc_bs_updated,  switches_couples_dc,  extremes_ZILs_dc  = _PMTP.DC_busbars_split_multiconductor_updated(data_help_updated,splitted_bus_dc)


for sc in eachindex(switches_couples_dc)
    println("dcswitch split: $(switches_couples_dc[sc]["dcswitch_split"])")
    println("terminal $(switches_couples_dc[sc]["terminal"]), f_sw $(switches_couples_dc[sc]["f_sw"]), t_sw $(switches_couples_dc[sc]["t_sw"])")
end


for (sw_id,sw) in data_help_dc_bs["dcswitch"]
    println("-----")
    if haskey(sw, "auxiliary")
        println("Switch $sw_id, from bus: $(sw["f_busdc"]), to bus: $(sw["t_busdc"]), auxiliary: $(sw["auxiliary"]), original $(sw["original"]), terminal: $(sw["terminal"])")
    else
        println("Switch $sw_id, from bus: $(sw["f_busdc"]), to bus: $(sw["t_busdc"]), terminal: $(sw["terminal"])")
    end
end

data_help_dc_bs_base["dcswitch"] = Dict{String,Any}()
diocane = trying_model_dc_switch(data_help_dc_bs_updated, _PM.ACPPowerModel, ipopt)

for i in 1:3
    data_help_dc_bs_updated["dcswitch"]["$i"]["cost"] = 100.0
end
result = _PMMCDC.solve_mcdc_acdcsw_DC(data_help_dc_bs_updated,_PM.ACPPowerModel,juniper)


data_help_bs = deepcopy(data_help_dc_bs_updated)
feasibility_check = deepcopy(data_help_dc_bs_updated)
_PMTP.prepare_AC_feasibility_check_DC_busbars_multiconductor(result,data_help_bs,feasibility_check,switches_couples_dc,extremes_ZILs_dc,data)
result_fc = _PMMCDC.solve_mcdcopf_fc_dc_bs(feasibility_check, _PM.ACPPowerModel, ipopt)




############

for (sw_id,sw) in data_help_dc_bs["dcswitch"]
    if haskey(sw, "auxiliary")
        println("Switch $sw_id info: f_busdc $(sw["f_busdc"]), t_busdc $(sw["t_busdc"]), auxiliary: $(sw["auxiliary"]), original $(sw["original"]), terminal: $(sw["terminal"])")
    else
        println("Switch $sw_id info: f_busdc $(sw["f_busdc"]), t_busdc $(sw["t_busdc"]), terminal: $(sw["terminal"])")
    end
end


for sw_id in 1:length(data_help_dc_bs["dcswitch"])
    println("Switch $sw_id, status $(result["solution"]["dcswitch"]["$sw_id"]["status"])")
end


[[l_id,l["pd"],l["load_bus"]] for (l_id,l) in data_help_dc_bs_base["load"]]
[[l_id,l["pd"],l["load_bus"]] for (l_id,l) in data_help_dc_bs_base["load"]]

sum(data_help_ac_bs["load"]["$l"]["pd"] for l in keys(data_help_dc_bs_base["load"]))
sum(data_help_dc_bs_base["load"]["$l"]["pd"] for l in keys(data_help_dc_bs_base["load"]))


[result["solution"]["gen"][g_id]["pg"] for (g_id,g) in data_help_dc_bs["gen"]]
[result_ac["solution"]["gen"][g_id]["pg"] for (g_id,g) in data_help_dc_bs_base["gen"]]

[[g_id,g["gen_bus"],result["solution"]["gen"][g_id]["pg"]] for (g_id,g) in data_help_dc_bs["gen"]]
[[g_id,g["gen_bus"],result_ac["solution"]["gen"][g_id]["pg"]] for (g_id,g) in data_help_dc_bs_base["gen"]]

sum(result["solution"]["gen"][g_id]["pg"] for (g_id,g) in data_help_dc_bs["gen"])
sum(result_ac["solution"]["gen"][g_id]["pg"] for (g_id,g) in data_help_dc_bs_base["gen"])


[result["solution"]["branch"][g_id]["pf"] for (g_id,g) in data_help_dc_bs["branch"]]
[result_ac["solution"]["branch"][g_id]["pf"] for (g_id,g) in data_help_dc_bs_base["branch"]]

[result["solution"]["branchdc"][g_id]["i_from"] for (g_id,g) in data_help_dc_bs["branchdc"]]
[result_ac["solution"]["branchdc"][g_id]["i_from"] for (g_id,g) in data_help_dc_bs_base["branchdc"]]

[data_help_ac_bs["gen"]["$l"]["cost"] for l in keys(data_help_dc_bs_base["gen"])]
[data_help_dc_bs_base["gen"]["$l"]["cost"] for l in keys(data_help_dc_bs_base["gen"])]
