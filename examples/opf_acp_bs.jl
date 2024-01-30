# OPF problem, nonlinear formulation
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import PowerModelsACDC as _PMACDC
import PowerModelsTopologicalActionsII as _PMTP
import Ipopt
import JuMP
using Gurobi
using Juniper

nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer)
juniper = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => gurobi, "time_limit" => 36000)


test_case = "case5_2grids_MC.m"

#file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/balanced/$(test_case)"
file = "$(dirname(@__DIR__))/test/data/matacdc_scripts_opf_paper/unbalanced/$(test_case)"


data_mcdc = _PMMCDC.parse_file(file)


s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(data_mcdc, _PM.ACPPowerModel, nlp_solver, setting=s)

###################################################################
# Printing the convdc and branchdc
for (conv_id, conv) in data_mcdc["convdc"]
    print("Converter $(conv_id) has: \n")
    print("      Conv_confi $(conv["conv_confi"])","\n")
    print("      Connect_at $(conv["connect_at"])","\n")
    print("      ground_type $(conv["ground_type"])","\n")
    print("      ground_z  $(conv["ground_z"])","\n")
    print("      Status p  $(conv["status_p"])","\n")
    print("      Status n  $(conv["status_n"])","\n")
    print("      AC bus $(conv["busac_i"])","\n")
    print("      DC bus  $(conv["busdc_i"])","\n")
    print("\n")
    print("\n")
end

for (br_id, br) in data_mcdc["branchdc"]
    print("DC branch $(br_id) has: \n")
    print("      line_confi $(br["line_confi"])","\n")
    print("      Connect_at $(br["connect_at"])","\n")
    print("      return_type $(br["return_type"])","\n")
    print("      return_z  $(br["return_z"])","\n")
    print("      Status p  $(br["status_p"])","\n")
    print("      Status n  $(br["status_n"])","\n")
    print("      Status r  $(br["status_r"])","\n")
    print("      From DC bus $(br["fbusdc"])","\n")
    print("      To DC bus  $(br["tbusdc"])","\n")
    print("\n")
    print("\n")
end

for (br_id, br) in data_mcdc["branch"]
    print("AC branch $(br_id) has: \n")
    print("      From AC bus $(br["f_bus"])","\n")
    print("      To AC bus  $(br["t_bus"])","\n")
    print("\n")
    print("\n")
end

###################################################################

result_mcdc = _PMMCDC.solve_mcdcopf_bs(data_mcdc, _PM.ACPPowerModel, juniper, setting=s)



# Adding AC busbar splitting of bus 2 and 7
data_busbar_split_mcdc = deepcopy(data_mcdc)

# Selecting which busbars are split
splitted_bus_ac = [2, 7]


data_busbar_split_mcdc,  switches_couples_ac_5,  extremes_ZILs_5_ac  = _PMTP.AC_busbar_split_more_buses(data_busbar_split_mcdc,splitted_bus_ac)

# One can select whether the branches originally linked to the split busbar are reconnected to either part of the split busbar or not
# Reconnect all the branches
result_busbar_split_mcdc = _PMMCDC.solve_mcdcopf_ac_bs(data_busbar_split_mcdc,_PM.ACPPowerModel,juniper, setting=s)


for (sw_id, sw) in result_busbar_split_mcdc["solution"]["switch"]
    print([sw_id,sw["status"]],"\n")
end


###################################################################
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
