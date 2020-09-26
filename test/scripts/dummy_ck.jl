using LinearAlgebra
using LinearAlgebra: I
import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
const _PMMCDC= PowerModelsMCDC
# import PowerModelsDistribution
# const _PD = PowerModelsDistribution

using InfrastructureModels
const _IM=InfrastructureModels
using JuMP
using Ipopt
using Memento



ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)


function build_mc_data!(base_data)
# function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    PowerModelsMCDC.process_additional_data!(mp_data)
    # _PD.make_multiconductor!(mp_data, conductors)
    PowerModelsMCDC._make_multiconductor_new!(mp_data)
    return mp_data
end

datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result1 = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.DCPPowerModel, ipopt_solver, setting = s)

datadc_new["branchdc"]["3"]["confi"]
datadc_new["branchdc"]["3"]["conductors"]
datadc_new["convdc"]["1"]["acrated"]
datadc_new["convdc"]["1"]["Pacrated"]
println(datadc_new["convdc"]["1"])

haskey(data11["branchdc"]["1"], "confi")

for (i,j) in datadc_new["branchdc"]["1"]
    println(i)
    println("gap1")
    # println(j)
    # println("gap2")
    break
end
