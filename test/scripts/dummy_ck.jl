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

file="./test/data/matacdc_scripts/case5_2grids_MC.m"
data11 = _PM.parse_file("./test/data/matacdc_scripts/case5_2grids_MC.m")

# result = _PMACDC.run_acdcopf("./test/data/matacdc_scripts/case5_2grids_MC.m", _PM.ACPPowerModel, ipopt_solver)

result1 = run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver)

data = _PM.parse_file("../PowerModelsMCDC.jl/test/data/matacdc_scripts/case5_2grids_MC.m")

data11 = _PM.parse_file("./test/data/matacdc_scripts/case5_2grids_MC.m")


# ==============================

datadc = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")

function build_mc_data!(base_data; conductors::Int=3)
# function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    # _PMACDC.process_additional_data!(base_data)
    # _PD.make_multiconductor!(mp_data, conductors)
    _PMMCDC._make_multiconductor!(mp_data, conductors)
    return mp_data
end

result = run_mcdcopf(datadc, _PM.DCPPowerModel, ipopt_solver)


datadc["busdc"]["1"]["Vdcmax"]
datadc["bus"]["1"]["vmax"]

datadc["branchdc"]["1"]["r"][2]
datadc["branch"]["1"]["r"][2]

################### new multiconductor#####

datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")

function build_mc_data!(base_data)
# function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    # _PMACDC.process_additional_data!(base_data)
    # _PD.make_multiconductor!(mp_data, conductors)
    _make_multiconductor_new!(mp_data)
    return mp_data
end

data11["branchdc"]["1"]["confi"]
data11["convdc"]["1"]["confi"]

datadc_new["branchdc"]["3"]["confi"]

haskey(data11["branchdc"]["1"], "confi")

for (i,j) in data11["branchdc"]["1"]
    println(i)
    println(j)
    println("gap")
end
