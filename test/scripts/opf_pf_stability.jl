using LinearAlgebra
using LinearAlgebra: I
import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
const _PMMCDC = PowerModelsMCDC
using PowerModelsACDC
const _PMACDC = PowerModelsACDC
using InfrastructureModels
const _IM = InfrastructureModels
using JuMP
using Ipopt
using Memento

# nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0, "bound_push"=>1e-4, "bound_frac"=>1e-4, "print_user_options"=>"yes")
file = "./test/data/matacdc_scripts_pf/Three_terminal_mcdc_pf.m"


# result = run_ots("../test/data/matpower/case3.m", ACPPowerModel, minlp_solver)

# ######################### single conductor model test (ACDC) #########################
# s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
# resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)



# # ######################### multiconductor model test (MCDC) #########################

# s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
# result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)


# # ######################### analyze results #########################

# printstyled("ACDC OPF\n"; bold=true)
# println(" termination status: ", resultAC["termination_status"])
# println("          objective: ", resultAC["objective"])
# println("         solve time: ", resultAC["solve_time"])

# printstyled("ACDC OPF\n"; bold=true)
# println(" termination status: ", result_mcdc_opf["termination_status"])
# println("          objective: ", resuresult_mcdc_opfltAC["objective"])
# println("         solve time: ", result_mcdc_opf["solve_time"])


