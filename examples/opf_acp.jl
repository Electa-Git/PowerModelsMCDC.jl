#example of opf problem
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
using JuMP
using Ipopt

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
file= "./test/data/matacdc_scripts/case5_2grids_MC.m"

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting = s)

#--------------------------------------------------------------------------------------------------------
result_acdc = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting = s)

#############

println("termination status of the acdc_opf is:", result_acdc["termination_status"])
println(" Objective acdc_opf is:", result_acdc["objective"])
println(" solve time acdc_opf is:", result_acdc["solve_time"])

println("termination status of the mcdc_opf is:", result_mcdc["termination_status"])
println(" Objective mcdc_opf is:", result_mcdc["objective"])
println(" solve time mcdc_opf is:", result_mcdc["solve_time"])
