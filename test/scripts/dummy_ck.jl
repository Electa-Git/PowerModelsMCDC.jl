using LinearAlgebra
using LinearAlgebra: I
import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
# import PowerModelsDistribution
# const _PD = PowerModelsDistribution

using InfrastructureModels
using JuMP
using Ipopt



ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)

file="./test/data/matacdc_scripts/case5_2grids_MC.m"
data11 = _PM.parse_file("./test/data/matacdc_scripts/case5_2grids_MC.m")

result = _PMACDC.run_acdcopf("./test/data/matacdc_scripts/case5_2grids_MC.m", _PM.ACPPowerModel, ipopt_solver)

result1 = run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver)

data = _PM.parse_file("../PowerModelsMCDC.jl/test/data/matacdc_scripts/case5_2grids_MC.m")

data11 = _PM.parse_file("./test/data/matacdc_scripts/case5_2grids_MC.m")



# datadc = build_mn_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m"; replicates::Int=3, conductors::Int=3)
# datadc = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")
#
# function build_mc_data!(base_data; conductors::Int=3)
#     mp_data = PowerModels.parse_file(base_data)
#     # _PMACDC.process_additional_data!(base_data)
#     make_multiconductor!(mp_data["convdc"], conductors)
#     return mp_data
# end
#
# include("./multi_conductor_functions.jl")


# ==============================

datadc = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")

function build_mc_data!(base_data; conductors::Int=3)
# function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    # _PMACDC.process_additional_data!(base_data)
    # _PD.make_multiconductor!(mp_data, conductors)
    _make_multiconductor!(mp_data, conductors)
    return mp_data
end

result = run_mcdcopf(datadc, _PM.DCPPowerModel, ipopt_solver)


datadc["busdc"]["1"]["Vdcmax"]
datadc["bus"]["1"]["vmax"]

datadc["branchdc"]["1"]["r"][2]
datadc["branch"]["1"]["r"][2]



#
# function build_mn_mc_data!(base_data; replicates::Int=3, conductors::Int=3)
#     mp_data = PowerModels.parse_file(base_data)
#     make_multiconductor!(mp_data, conductors)
#     mn_mc_data = PowerModels.replicate(mp_data, replicates)
#     mn_mc_data["conductors"] = mn_mc_data["nw"]["1"]["conductors"]
#     return mn_mc_data
# end
#
#
# function build_mn_mc_data!(base_data_1, base_data_2; conductors_1::Int=3, conductors_2::Int=3)
#     mp_data_1 = PowerModels.parse_file(base_data_1)
#     mp_data_2 = PowerModels.parse_file(base_data_2)
