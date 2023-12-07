# OPF problem, nonlinear formulation

import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt

nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

test_case = "case5_2grids_MC.m"

#file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/balanced/$(test_case)"
file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/unbalanced/$(test_case)"


s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, nlp_solver, setting=s)


## Comparison with PowerModelsACDC (single conductor model)

import PowerModelsACDC as _PMACDC

result_acdc = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, nlp_solver, setting=s)

printstyled("Multiconductor OPF\n"; bold=true)
println(" termination status: ", result_mcdc["termination_status"])
println("          objective: ", result_mcdc["objective"])
println("         solve time: ", result_mcdc["solve_time"])

printstyled("\nSingle-conductor OPF\n"; bold=true)
println(" termination status: ", result_acdc["termination_status"])
println("          objective: ", result_acdc["objective"])
println("         solve time: ", result_acdc["solve_time"])
