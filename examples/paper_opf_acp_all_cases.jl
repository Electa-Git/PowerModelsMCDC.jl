#this file is to replicate the results presented in the paper (uploaded on arxiv.org)
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import PowerModelsACDC as _PMACDC    #to be used while comparing acdc and mcdc results
using Ipopt

ipopt_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)


test_case = "case5_2grids_MC.m"

file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/unbalanced/$(test_case)"


s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)

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
