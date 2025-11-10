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
#for (cv_id, cv) in data["convdc"]
#    cv["transformer"] = 0
#    cv["reactor"] = 0
#    cv["filter"] = 0
#end

result_ac = _PMMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt, setting = s)
#result_lpac = _PMMCDC.solve_mcdcopf(data, _PM.LPACCPowerModel, ipopt, setting = s) # This to be checked
#result_dc = _PMMCDC.solve_mcdcopf(data, _PM.DCPPowerModel, gurobi, setting = s)

for (cv_id,cv) in data["convdc"]
    println([result_ac["solution"]["convdc"][cv_id]["pgrid"]])
end


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

function solve_ac_model_check(data::Dict{String,Any}, model_type::Type; kwargs...)
    return _PM.instantiate_model(data, model_type, _PMMCDC.build_mcdc_acdcsw_AC; ref_extensions=[_PMMCDC.add_ref_dcgrid_switch!], kwargs...)
end

function solve_ac_model_check_basic(data::Dict{String,Any}, model_type::Type; kwargs...)
    return _PM.instantiate_model(data, model_type, _PMMCDC.build_mcdcopf; ref_extensions=[_PMMCDC.add_ref_dcgrid!], kwargs...)
end

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

#pm_ac = solve_ac_model_check(data_help_ac_bs, _PM.ACPPowerModel)
#pm_ac_basic = solve_ac_model_check(data_help, _PM.ACPPowerModel)

result = _PMMCDC.solve_mcdc_acdcsw_AC(data_help_ac_bs,_PM.ACPPowerModel,juniper)



for (cv_id,cv) in data_help_ac_bs["convdc"]
    println("Converter $cv_id, ac bus: $(cv["busac_i"])")
end
#=
splitted_bus_ac = 7
data_help_ac_bs_base = deepcopy(data_help)
data_help_ac_bs,  switches_couples_ac,  extremes_ZILs_ac  = _PMTP.AC_busbars_split_multiconductor(data_help_ac_bs_base,splitted_bus_ac)

for (cv_id,cv) in data_help["convdc"]
    println("Converter $cv_id, ac bus: $(cv["busac_i"])")
end
=#
for (sw_id,sw) in data_help_dc_bs["switch"]
    if haskey(sw, "auxiliary")
        println("Switch $sw_id, from bus: $(sw["f_bus"]), to bus: $(sw["t_bus"]), auxiliary: $(sw["auxiliary"])")
    end
end

for i in 1:length(data_help_ac_bs["switch"])
    if haskey(data_help_ac_bs["switch"]["$i"], "auxiliary")
        println("Switch $i, from bus: $(data_help_ac_bs["switch"]["$i"]["f_bus"]), to bus: $(data_help_ac_bs["switch"]["$i"]["t_bus"]), auxiliary: $(data_help_ac_bs["switch"]["$i"]["auxiliary"]), status: $(result["solution"]["switch"]["$i"]["status"])")
    else
        println("Switch $i, from bus: $(data_help_ac_bs["switch"]["$i"]["f_bus"]), to bus: $(data_help_ac_bs["switch"]["$i"]["t_bus"]), status: $(result["solution"]["switch"]["$i"]["status"])")
    end
end

feasibility_check = deepcopy(data_help_ac_bs)
_PMTP.prepare_AC_feasibility_check_AC_busbars_multiconductor(result,data_help_ac_bs,feasibility_check,switches_couples_ac,extremes_ZILs_ac,data_help)
result_fc = _PMMCDC.solve_mcdcopf_fc(feasibility_check, _PM.ACPPowerModel, ipopt)

################
using JSON

json_opf = JSON.json(result_ac)
open(joinpath(results_folder,"mcdcOPF_case_5.json"),"w") do f 
    write(f, json_opf) 
end

json_split = JSON.json(result)
open(joinpath(results_folder,"mcdcBuS_case_5_split_2.json"),"w") do f 
    write(f, json_split) 
end

json_split_fc = JSON.json(result_fc)
open(joinpath(results_folder,"mcdcFC_case_5_split_2.json"),"w") do f 
    write(f, json_split_fc) 
end


################

for (g_id,g) in data_help_ac_bs["gen"]
    println("Generator $g_id, bus: $(g["gen_bus"])")
    println("Pg for BuS is $(result_fc["solution"]["gen"][g_id]["pg"])")
    println("Pg for OPF is $(result_ac["solution"]["gen"][g_id]["pg"])")
end

for (b_id,b) in data_help_ac_bs["bus"]
    println("-------------------")
    println("Bus $b_id")
    println("Vm for BuS is $(result_fc["solution"]["bus"][b_id]["vm"])")
    if haskey(result_ac["solution"]["bus"],b_id)
        println("Vm for OPF is $(result_ac["solution"]["bus"][b_id]["vm"])")
    else
        println("Vm for OPF is not available")
    end
    println("-------------")
    println("Va for BuS is $(result_fc["solution"]["bus"][b_id]["va"])")
    if haskey(result_ac["solution"]["bus"],b_id)
        println("Va for OPF is $(result_ac["solution"]["bus"][b_id]["va"])")
    else
        println("Va for OPF is not available")
    end
end


for (br_id,br) in data_help_ac_bs["branch"]
    println("-------------------")
    println("Branch $br_id")
    println("Pf for BuS is $(result_fc["solution"]["branch"][br_id]["pf"])")
    println("Pf for OPF is $(result_ac["solution"]["branch"][br_id]["pf"])")
end

for (cv_id,cv) in data_help_ac_bs["convdc"]
    println("-------------------")
    println("Converter $cv_id")
    for pole in keys(cv["status"])
        println("  Pole: $pole")
        println("    pgrid for BuS is ",result_fc["solution"]["convdc"][cv_id]["pgrid"][pole])
        println("    pgrid for OPF is ",result_ac["solution"]["convdc"][cv_id]["pgrid"][pole])
    end
end

for (br_id,br) in feasibility_check["branch"]
    println(br_id," ",br["f_bus"]," ",br["t_bus"])
end


#####################################
using Plots
using StatsPlots

br_bus = [abs(result_fc["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_ac_bs["branch"])]
br_bus_opf = [abs(result_ac["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_ac_bs["branch"])]
br_utilization = vcat(br_bus_opf, br_bus)
sx = repeat(["OPF", "BuS - FC"], inner = length(data_help_ac_bs["branch"]))
name_try = collect(1:length(data_help_ac_bs["branch"]))
name = vcat(name_try, name_try)

groupedbar(name, br_utilization, group = sx, ylabel = "Branch utilization", xlabel = "Branch number", xticks = 1:1:length(data_help_ac_bs["branch"]), yticks = 0:0.2:10, ylims = (0,1.01),
title = "", bar_width = 0.7, color = [:grey40 :grey70])

######
diff_va_bus = [abs(result_fc["solution"]["bus"]["$(feasibility_check["branch"]["$br_id"]["f_bus"])"]["va"] - result_fc["solution"]["bus"]["$(feasibility_check["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(feasibility_check["branch"])]
diff_va_bus_opf = [abs(result_ac["solution"]["bus"]["$(data_help["branch"]["$br_id"]["f_bus"])"]["va"] - result_ac["solution"]["bus"]["$(data_help["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(data_help["branch"])]

diff_va_utilization = vcat(diff_va_bus, diff_va_bus_opf)
sx = repeat(["BuS - FC","OPF"], inner = length(data_help_ac_bs["branch"]))
name_try = collect(1:length(data_help_ac_bs["branch"]))
name = vcat(name_try, name_try)

groupedbar(name, diff_va_utilization, group = sx, ylabel = "Voltage angle difference over a branch", xlabel = "Branch number", xticks = 1:1:length(data_help_ac_bs["branch"]), yticks = 0:0.2:pi/3, ylims = (0,pi/3),
title = "", bar_width = 0.7, color = [:grey40 :grey70])


#######
va_bus = [abs(result_fc["solution"]["bus"]["$b_id"]["va"]) for b_id in 1:12]
va_bus_opf = [abs(result_ac["solution"]["bus"]["$b_id"]["va"]) for b_id in 1:11]
push!(va_bus_opf,0.0) 

vm_bus = [abs(result_fc["solution"]["bus"]["$b_id"]["vm"]) for b_id in 1:12]
vm_bus_opf = [abs(result_ac["solution"]["bus"]["$b_id"]["vm"]) for b_id in 1:11]
push!(vm_bus_opf,0.0) 


va_bus_comparison = vcat(va_bus_opf,va_bus)
sx = repeat(["OPF", "BuS - FC"], inner = 12)
name_try = collect(1:12)
name = vcat(name_try, name_try)
groupedbar(name, va_bus_comparison, group = sx, ylabel = "Voltage angle [rad]", xlabel = "Bus number", xticks = 1:1:12, ylims = (0,pi/2),
title = "", bar_width = 0.7, color = [:grey40 :grey70])

vm_bus_comparison = vcat(vm_bus_opf,vm_bus)
sx = repeat(["OPF", "BuS - FC"], inner = 12)
name_try = collect(1:12)
name = vcat(name_try, name_try)
groupedbar(name, vm_bus_comparison, group = sx, ylabel = "Voltage magnitude [pu]", xlabel = "Bus number", xticks = 1:1:12, ylims = (0.8,1.2),
title = "", bar_width = 0.7, color = [:grey40 :grey70])

#######

i_br_dc_bus = [result_fc["solution"]["branchdc"]["$br_id"]["i_from"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_br_dc_bus_opf = [result_ac["solution"]["branchdc"]["$br_id"]["i_from"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
poles_dc = [i for br_id in 1:length(data_help_ac_bs["branchdc"]) for i in eachindex(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_br_dc_current = vcat(i_br_dc_bus_opf, i_br_dc_bus)
#=
sx = repeat(["OPF", "BuS - FC"], inner = sum(length(data_help_ac_bs["branchdc"]["$(br_id_dc)"]["status"]) for br_id_dc in 1:length(data_help_ac_bs["branchdc"])))

name_try = collect(1:sum(length(data_help_ac_bs["branchdc"]["$(br_id_dc)"]["status"]) for br_id_dc in 1:length(data_help_ac_bs["branchdc"])))
name = vcat(name_try, name_try)

groupedbar(poles_dc, br_dc_current, group = sx, ylabel = "Current through pole", xlabel = "DC branch number", xticks = 1:1:length([]), yticks = 0:0.2:10, ylims = (0,1.01),
title = "", bar_width = 0.7, color = [:grey40 :grey70])
=#        
i_cv_dc_bus = [result_fc["solution"]["convdc"]["$br_id"]["iconv_dc"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_cv_dc_bus_opf = [result_ac["solution"]["convdc"]["$br_id"]["iconv_dc"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_cv_dc_current = vcat(p_cv_dc_bus_opf, p_cv_dc_bus)


p_cv_dc_bus = [result_fc["solution"]["convdc"]["$br_id"]["pgrid"][pole] for br_id in 1:length(data_help_ac_bs["convdc"]) for pole in keys(data_help_ac_bs["convdc"]["$br_id"]["status"])]
p_cv_dc_bus_opf = [result_ac["solution"]["convdc"]["$br_id"]["pgrid"][pole] for br_id in 1:length(data_help_ac_bs["convdc"]) for pole in keys(data_help_ac_bs["convdc"]["$br_id"]["status"])]
poles_cv_dc = [i for br_id in 1:length(data_help_ac_bs["convdc"]) for i in eachindex(data_help_ac_bs["convdc"]["$br_id"]["status"])]
p_cv_dc_current = vcat(p_cv_dc_bus_opf, p_cv_dc_bus)


for (br_dc_id,br_dc) in data["branchdc"]
    println("branchdc $br_dc_id:, f_bus: $(br_dc["fbusdc"]), t_bus: $(br_dc["tbusdc"])")
end

##### Upload results
using JSON

results_folder = "/Users/giacomobastianel/Library/CloudStorage/OneDrive-KULeuven/Papers/ACDC_2026/PMMCDC_rebirth/Results"
bs_2   = JSON.parsefile(joinpath(results_folder,"mcdcBuS_case_5_split_2.json"))
bs_7   = JSON.parsefile(joinpath(results_folder,"mcdcBuS_case_5_split_7.json"))
bs_2_7 = JSON.parsefile(joinpath(results_folder,"mcdcBuS_case_5_split_2_7.json"))

fc_2 = JSON.parsefile(joinpath(results_folder,"mcdcFC_case_5_split_2.json"))
fc_7 = JSON.parsefile(joinpath(results_folder,"mcdcFC_case_5_split_7.json"))
fc_2_7 = JSON.parsefile(joinpath(results_folder,"mcdcFC_case_5_split_2_7.json"))


data_help = deepcopy(data)
data_help_2   = deepcopy(data_help)
data_help_7   = deepcopy(data_help)
data_help_2_7 = deepcopy(data_help)


splitted_bus_ac_2   = 2
splitted_bus_ac_7   = 7
splitted_bus_ac_2_7 = [2,7]
data_help_2  ,  sw_couples_2   ,  extremes_ZILs_ac_2    = _PMTP.AC_busbars_split_multiconductor(data_help_2  ,splitted_bus_ac_2  )
data_help_7  ,  sw_couples_7   ,  extremes_ZILs_ac_7    = _PMTP.AC_busbars_split_multiconductor(data_help_7  ,splitted_bus_ac_7  )
data_help_2_7,  sw_couples_2_7 ,  extremes_ZILs_ac_2_7  = _PMTP.AC_busbars_split_multiconductor(data_help_2_7,splitted_bus_ac_2_7)

feasibility_check_2   = deepcopy(data_help_2  )
feasibility_check_7   = deepcopy(data_help_7  )
feasibility_check_2_7 = deepcopy(data_help_2_7)

_PMTP.prepare_AC_feasibility_check_AC_busbars_multiconductor(bs_2  ,data_help_2  ,feasibility_check_2  ,sw_couples_2   ,  extremes_ZILs_ac_2  ,data_help)
_PMTP.prepare_AC_feasibility_check_AC_busbars_multiconductor(bs_7  ,data_help_7  ,feasibility_check_7  ,sw_couples_7   ,  extremes_ZILs_ac_7  ,data_help)
_PMTP.prepare_AC_feasibility_check_AC_busbars_multiconductor(bs_2_7,data_help_2_7,feasibility_check_2_7,sw_couples_2_7 ,  extremes_ZILs_ac_2_7,data_help)



#############################

using Plots
using StatsPlots

br_bus_opf = [abs(result_ac["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_2["branch"])]
br_bus_2 = [abs(fc_2["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_2["branch"])]
br_bus_7 = [abs(fc_7["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_2["branch"])]
br_bus_2_7 = [abs(fc_2_7["solution"]["branch"]["$br_id"]["pf"]) for br_id in 1:length(data_help_2["branch"])]

br_utilization = vcat(br_bus_opf, br_bus_2, br_bus_7, br_bus_2_7)
sx = repeat(["OPF", "Split bus 2", "Split bus 7 ", "Split bus 2 & 7"], inner = length(data_help_2["branch"]))
name_try = collect(1:length(data_help_2["branch"]))
name = vcat(name_try, name_try, name_try, name_try)

groupedbar(name, br_utilization.*100, group = sx, ylabel = "Branch utilization [%]", xlabel = "Branch number", xticks = 1:1:length(data_help_2["branch"]), yticks = 0:20:100, ylims = (0,101),title = "", bar_width = 0.7, color = [:grey20 :grey40 :grey60 :grey80], grid = :none)

figures_folder = "/Users/giacomobastianel/Library/CloudStorage/OneDrive-KULeuven/Papers/ACDC_2026/PMMCDC_rebirth/Figures"
savefig(joinpath(figures_folder,"branch_utilization_comparison.png"))
savefig(joinpath(figures_folder,"branch_utilization_comparison.pdf"))
savefig(joinpath(figures_folder,"branch_utilization_comparison.svg"))

######
diff_va_bus_opf = [abs(result_ac["solution"]["bus"]["$(data_help["branch"]["$br_id"]["f_bus"])"]["va"] - result_ac["solution"]["bus"]["$(data_help["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(data_help["branch"])]
diff_va_bus_2   = [abs(fc_2["solution"]["bus"]["$(feasibility_check_2["branch"]["$br_id"]["f_bus"])"]["va"] - fc_2["solution"]["bus"]["$(feasibility_check_2["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(feasibility_check_2["branch"])]
diff_va_bus_7   = [abs(fc_7["solution"]["bus"]["$(feasibility_check_7["branch"]["$br_id"]["f_bus"])"]["va"] - fc_7["solution"]["bus"]["$(feasibility_check_7["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(feasibility_check_7["branch"])]
diff_va_bus_2_7 = [abs(fc_2_7["solution"]["bus"]["$(feasibility_check_2_7["branch"]["$br_id"]["f_bus"])"]["va"] - fc_2_7["solution"]["bus"]["$(feasibility_check_2_7["branch"]["$br_id"]["t_bus"])"]["va"]) for br_id in 1:length(feasibility_check_2_7["branch"])]

diff_va_utilization = vcat(diff_va_bus_opf, diff_va_bus_2, diff_va_bus_7, diff_va_bus_2_7)
sx = repeat(["OPF", "BuS 2 split", "BuS 7 split", "BuS 2 & 7 split"], inner = length(data_help_2["branch"]))
name_try = collect(1:length(data_help_2["branch"]))
name = vcat(name_try, name_try, name_try, name_try)

groupedbar(name, diff_va_utilization, group = sx, ylabel = "Voltage angle difference over a branch", xlabel = "Branch number", xticks = 1:1:length(data_help["branch"]), yticks = 0:0.2:pi/3, ylims = (0,pi/3),
title = "", bar_width = 0.7, color = [:grey20 :grey40 :grey60 :grey80])


#######
va_bus_opf = [abs(result_ac["solution"]["bus"]["$b_id"]["va"]) for b_id in 1:11]
push!(va_bus_opf,0.0) 

va_2_opf = result_ac["solution"]["bus"]["2"]["va"]
va_7_opf = ones(4)*result_ac["solution"]["bus"]["7"]["va"]

va_2_bs = [0, fc_2["solution"]["bus"]["2"]["va"], 0, fc_2_7["solution"]["bus"]["2"]["va"]]
va_7_bs = [0, 0, fc_2["solution"]["bus"]["7"]["va"], fc_2_7["solution"]["bus"]["7"]["va"]]

va_12_bs = [0,fc_2["solution"]["bus"]["12"]["va"], 0, fc_2_7["solution"]["bus"]["12"]["va"]]
va_13_bs = [0,0,fc_7["solution"]["bus"]["12"]["va"], fc_2_7["solution"]["bus"]["13"]["va"]]

vm_bus = [abs(result_fc["solution"]["bus"]["$b_id"]["vm"]) for b_id in 1:12]
vm_bus_opf = [abs(result_ac["solution"]["bus"]["$b_id"]["vm"]) for b_id in 1:11]
push!(vm_bus_opf,0.0) 

va_1 = [result_ac["solution"]["bus"]["2"]["va"],result_ac["solution"]["bus"]["7"]["va"], 0                                   , 0] 
va_2 = [fc_2["solution"]["bus"]["2"]["va"]     ,fc_2["solution"]["bus"]["7"]["va"]     , fc_2["solution"]["bus"]["12"]["va"]  , 0] 
va_3 = [fc_7["solution"]["bus"]["2"]["va"]     ,fc_7["solution"]["bus"]["7"]["va"]     , 0                                   , fc_7["solution"]["bus"]["12"]["va"] ]
va_4 = [fc_2_7["solution"]["bus"]["2"]["va"]   ,fc_2_7["solution"]["bus"]["7"]["va"]   ,fc_2_7["solution"]["bus"]["12"]["va"],fc_2_7["solution"]["bus"]["13"]["va"]]

vas = vcat(va_1,va_2,va_3,va_4)
sx = repeat(["OPF", "Split bus 2", "Split bus 7", "Split bus 2 & 7"], inner = 4)
name_try = collect(1:4)
name = vcat(name_try, name_try, name_try, name_try)

groupedbar(name, vas.*180, group = sx, ylabel = "Bus voltage angle (°)", xticks = (1:4, ["Bus 2", "Bus 7", "Bus 2 - split", "Bus 7 - split"]), yticks = -60:30:60, ylims = (-65,65),
bar_width = 0.7, color = [:grey20 :grey40 :grey60 :grey80],grid = :none)

savefig(joinpath(figures_folder,"bus_voltage_angle_comparison.png"))
savefig(joinpath(figures_folder,"bus_voltage_angle_comparison.pdf"))
savefig(joinpath(figures_folder,"bus_voltage_angle_comparison.svg"))

####

vm_1 = [result_ac["solution"]["bus"]["2"]["vm"],result_ac["solution"]["bus"]["7"]["vm"], 0                                   , 0] 
vm_2 = [fc_2["solution"]["bus"]["2"]["vm"]     ,fc_2["solution"]["bus"]["7"]["vm"]     , fc_2["solution"]["bus"]["12"]["vm"]  , 0] 
vm_3 = [fc_7["solution"]["bus"]["2"]["vm"]     ,fc_7["solution"]["bus"]["7"]["vm"]     , 0                                   , fc_7["solution"]["bus"]["12"]["vm"] ]
vm_4 = [fc_2_7["solution"]["bus"]["2"]["vm"]   ,fc_2_7["solution"]["bus"]["7"]["vm"]   ,fc_2_7["solution"]["bus"]["12"]["vm"],fc_2_7["solution"]["bus"]["13"]["vm"]]

vms = vcat(vm_1,vm_2,vm_3,vm_4)
sx = repeat(["OPF", "Split bus 2", "Split bus 7", "Split bus 2 & 7"], inner = 4)
name_try = collect(1:4)
name = vcat(name_try, name_try, name_try, name_try)

groupedbar(name, vms, group = sx, ylabel = "Bus voltage magnitude (pu)", xticks = (1:4, ["Bus 2", "Bus 7", "Bus 2 - split", "Bus 7 - split"]), yticks = 0.9:0.05:1.1, ylims = (0.88,1.12),
bar_width = 0.7, color = [:grey20 :grey40 :grey60 :grey80],grid = :none)

savefig(joinpath(figures_folder,"bus_voltage_magnitude_comparison.png"))
savefig(joinpath(figures_folder,"bus_voltage_magnitude_comparison.pdf"))
savefig(joinpath(figures_folder,"bus_voltage_magnitude_comparison.svg"))

#######

gen_bus_opf = [abs(result_ac["solution"]["gen"]["$br_id"]["pg"]) for br_id in 1:length(data_help_2["gen"])]
gen_bus_2 = [abs(fc_2["solution"]["gen"]["$br_id"]["pg"]) for br_id in 1:length(data_help_2["gen"])]
gen_bus_7 = [abs(fc_7["solution"]["gen"]["$br_id"]["pg"]) for br_id in 1:length(data_help_2["gen"])]
gen_bus_2_7 = [abs(fc_2_7["solution"]["gen"]["$br_id"]["pg"]) for br_id in 1:length(data_help_2["gen"])]

gen_utilization = vcat(gen_bus_opf, gen_bus_2, gen_bus_7, gen_bus_2_7)
sx = repeat(["OPF", "Split bus 2", "Split bus 7 ", "Split bus 2 & 7"], inner = length(data_help_2["gen"]))
name_try = collect(1:length(data_help_2["gen"]))
name = vcat(name_try, name_try, name_try, name_try)

groupedbar(name, gen_utilization, group = sx, ylabel = "Generator power [pu]", xlabel = "Generator number & Bus ID", xticks = (1:1:length(data_help_2["gen"]),["Gen 1 - Bus 1", "Gen 2 - Bus 2", "Gen 3 - Bus 6", "Gen 4 - Bus 7", "Gen 5 - Bus 11"]), yticks = 0:0.5:2.0, ylims = (0,2.1),title = "", bar_width = 0.7, color = [:grey20 :grey40 :grey60 :grey80], grid = :none)

figures_folder = "/Users/giacomobastianel/Library/CloudStorage/OneDrive-KULeuven/Papers/ACDC_2026/PMMCDC_rebirth/Figures"
savefig(joinpath(figures_folder,"gen_comparison.png"))
savefig(joinpath(figures_folder,"gen_comparison.pdf"))
savefig(joinpath(figures_folder,"gen_comparison.svg"))












###########

i_br_dc_bus = [result_fc["solution"]["branchdc"]["$br_id"]["i_from"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_br_dc_bus_opf = [result_ac["solution"]["branchdc"]["$br_id"]["i_from"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
poles_dc = [i for br_id in 1:length(data_help_ac_bs["branchdc"]) for i in eachindex(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_br_dc_current = vcat(i_br_dc_bus_opf, i_br_dc_bus)
#=
sx = repeat(["OPF", "BuS - FC"], inner = sum(length(data_help_ac_bs["branchdc"]["$(br_id_dc)"]["status"]) for br_id_dc in 1:length(data_help_ac_bs["branchdc"])))

name_try = collect(1:sum(length(data_help_ac_bs["branchdc"]["$(br_id_dc)"]["status"]) for br_id_dc in 1:length(data_help_ac_bs["branchdc"])))
name = vcat(name_try, name_try)

groupedbar(poles_dc, br_dc_current, group = sx, ylabel = "Current through pole", xlabel = "DC branch number", xticks = 1:1:length([]), yticks = 0:0.2:10, ylims = (0,1.01),
title = "", bar_width = 0.7, color = [:grey40 :grey70])
=#        
i_cv_dc_bus = [result_fc["solution"]["convdc"]["$br_id"]["iconv_dc"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_cv_dc_bus_opf = [result_ac["solution"]["convdc"]["$br_id"]["iconv_dc"][pole] for br_id in 1:length(data_help_ac_bs["branchdc"]) for pole in keys(data_help_ac_bs["branchdc"]["$br_id"]["status"])]
i_cv_dc_current = vcat(p_cv_dc_bus_opf, p_cv_dc_bus)


p_cv_dc_bus = [result_fc["solution"]["convdc"]["$br_id"]["pgrid"][pole] for br_id in 1:length(data_help_ac_bs["convdc"]) for pole in keys(data_help_ac_bs["convdc"]["$br_id"]["status"])]
p_cv_dc_bus_opf = [result_ac["solution"]["convdc"]["$br_id"]["pgrid"][pole] for br_id in 1:length(data_help_ac_bs["convdc"]) for pole in keys(data_help_ac_bs["convdc"]["$br_id"]["status"])]
poles_cv_dc = [i for br_id in 1:length(data_help_ac_bs["convdc"]) for i in eachindex(data_help_ac_bs["convdc"]["$br_id"]["status"])]
p_cv_dc_current = vcat(p_cv_dc_bus_opf, p_cv_dc_bus)


for (br_dc_id,br_dc) in data["branchdc"]
    println("branchdc $br_dc_id:, f_bus: $(br_dc["fbusdc"]), t_bus: $(br_dc["tbusdc"])")
end

for (g_id,g) in data["gen"]
    println("gen $g_id:, cost $(g["cost"])")
end



for (cv_id,cv) in data["convdc"]
    println([cv_id,fc_2_7["solution"]["convdc"][cv_id]["pgrid"]])
end
