#this file is to replicae the results presented in the paper (uploaded on arxiv.org)
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import PowerModelsACDC as _PMACDC    #to be used while comparing acdc and mcdc results
using JuMP
using Ipopt
import PowerModelsTopologicalActionsII as _PMTP
using Gurobi
using Juniper
using Memento

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer)
juniper = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => gurobi, "time_limit" => 36000)


test_case = "case5_2grids_MC.m"

file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/unbalanced/$(test_case)"
data = _PMMCDC.parse_file(file)

s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt, setting=s)


splitted_bus_ac = 2
data, extremes_ZIL = _PMTP.AC_busbar_split_more_buses_fixed(data,splitted_bus_ac)
split_elements = _PMTP.elements_AC_busbar_split(data)

data_ac_fixed = deepcopy(data)
data_ac_fixed["branch"]["4"]["f_bus"] = extremes_ZIL["2"][2]
data_ac_fixed["branch"]["5"]["f_bus"] = extremes_ZIL["2"][2]

result_mcdc_bs = _PMMCDC.solve_mcdcopf_bs(data_ac_fixed, _PM.ACPPowerModel, juniper, setting=s)


#--------------------------------------------------------------------------------------------------------
dc_data = _PM.parse_file(file)
_PMACDC.process_additional_data!(dc_data)

result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting=s)


#############

println("termination status of the acdc_opf is:", result_acdc["termination_status"],"\n")
println(" Objective acdc_opf is:", result_acdc["objective"],"\n")
println(" solve time acdc_opf is:", result_acdc["solve_time"],"\n")

println("termination status of the mcdc_opf is:", result_mcdc["termination_status"],"\n")
println(" Objective mcdc_opf is:", result_mcdc["objective"],"\n")
println(" solve time mcdc_opf is:", result_mcdc["solve_time"],"\n")

#########

for (conv_id, conv) in dc_data["convdc"]
    print("Converter $(conv_id) has: \n")
    print("      Conv_confi $(conv["conv_confi"])","\n")
    print("      Connect_at $(conv["connect_at"])","\n")
    print("      ground_type $(conv["ground_type"])","\n")
    print("      ground_z  $(conv["ground_z"])","\n")
    print("\n")
    print("\n")
end

for (br_id, br) in dc_data["branchdc"]
    print("DC branch $(br_id) has: \n")
    print("      line_confi $(br["line_confi"])","\n")
    print("      Connect_at $(br["connect_at"])","\n")
    print("      return_type $(br["return_type"])","\n")
    print("      return_z  $(br["return_z"])","\n")
    print("\n")
    print("\n")
end
