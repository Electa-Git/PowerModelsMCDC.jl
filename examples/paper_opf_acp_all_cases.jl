#this file is to replicae the results presented in the paper (uploaded on arxiv.org)
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import PowerModelsACDC as _PMACDC    #to be used while comparing acdc and mcdc results
using JuMP
using Ipopt

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)


# file="./test/data/matacdc_scripts/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts/case39_mcdc.m"
# file="./test/data/matacdc_scripts/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts/case3120sp_mcdc.m"

file = "./test/data/matacdc_scripts_opf_paper/balanced/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case39_mcdc.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case3120sp_mcdc.m"

# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case39_mcdc.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case3120sp_mcdc.m"


s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)

#--------------------------------------------------------------------------------------------------------
dc_data = PowerModels.parse_file(file)
_PMACDC.process_additional_data!(dc_data)

result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting=s)


#############

println("termination status of the acdc_opf is:", result_acdc["termination_status"])
println(" Objective acdc_opf is:", result_acdc["objective"])
println(" solve time acdc_opf is:", result_acdc["solve_time"])

println("termination status of the mcdc_opf is:", result_mcdc["termination_status"])
println(" Objective mcdc_opf is:", result_mcdc["objective"])
println(" solve time mcdc_opf is:", result_mcdc["solve_time"])

#########

# N=100
# solve_time_dc=Dict([(l, Dict([("$i", 0.0000) for i in 1:4])) for l in 1:N])

# for k=1:N

#   result_mcdc = _PMMCDC.solve_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
#   result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting = s)


#     #  solve_time_dc[k]["1"] = result_mcdc["termination_status"]
#      solve_time_dc[k]["2"] = result_mcdc["solve_time"]
#     #  solve_time_dc[k]["3"] = result_acdc["termination_status"]
#      solve_time_dc[k]["4"] = result_acdc["solve_time"]

# end

# avg_solvetime_mcdc= sum(solve_time_dc[k]["2"] for k in 1:N)/N
# avg_solvetime_acdc= sum(solve_time_dc[k]["4"] for k in 1:N)/N

# println(" Objective mcdc_opf is:", result_mcdc["objective"])
# println(" Objective acdc_opf is:", result_acdc["objective"])

# println(" avg_solvetime_mcdcf is:",avg_solvetime_mcdc)
# println(" avg_solvetime_acdcf is:",avg_solvetime_acdc)