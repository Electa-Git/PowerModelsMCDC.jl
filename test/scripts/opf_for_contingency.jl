using LinearAlgebra
using LinearAlgebra: I
import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
const _PMMCDC = PowerModelsMCDC
# import PowerModelsDistribution
# const _PD = PowerModelsDistribution
using PowerModelsACDC
const _PMACDC = PowerModelsACDC

using InfrastructureModels
const _IM = InfrastructureModels
using JuMP
using Ipopt
using Memento
# using Gurobi
# using Cbc
# using Juniper

# print_level=1
# ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 1)
nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

# gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)
# couenne_solver=JuMP.with_optimizer(“C:/Users/mayar.madboly/Downloads/couenne-win64.exe”, print_level =0)

# ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=1)
# cbc_solver = JuMP.with_optimizer(Cbc.Optimizer)
# juniper = JuMP.with_optimizer(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt_solver)

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)



# file="./test/data/matacdc_scripts/case39_mcdc.m"
# file = "./test/data/matacdc_scripts/case5_2grids_MC.m"
# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf_1BP.m"

# file = "./test/data/matacdc_scripts/case5_2grids_MC_contingency.m"
file="./test/data/matacdc_scripts/case67mcdc_scopf4.m"


s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)
println("termination status of the opf is:", result_mcdc_opf["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf["objective"])


data = PowerModelsMCDC.parse_file(file)
n_cv=length(data["convdc"])
n_brdc=length(data["branchdc"])

N= 1+n_cv+n_brdc

results=Dict([(l, Dict()) for l in 1:N])
push!(results, 1=>result_mcdc_opf)

for k in 1:N-1
    if k <= n_cv
        data = PowerModelsMCDC.parse_file(file)
        data["convdc"]["$k"]["status"]=0
        result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
        K=k+1
        push!(results, K=>result_mcdc_opf)
    else 
        k_br=k-n_cv
        data = PowerModelsMCDC.parse_file(file)
        data["branchdc"]["$k_br"]["status"]=0
        result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
        K=k+1
        push!(results, K=>result_mcdc_opf)

    end
end 



for (case, opf_result) in results
    println("the objective value for case $case is ", opf_result["objective"])
end 