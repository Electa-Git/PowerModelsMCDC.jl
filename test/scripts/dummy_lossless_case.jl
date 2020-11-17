using LinearAlgebra
using LinearAlgebra: I
import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
const _PMMCDC= PowerModelsMCDC
# import PowerModelsDistribution
# const _PD = PowerModelsDistribution
using PowerModelsACDC
const _PMACDC= PowerModelsACDC

using InfrastructureModels
const _IM=InfrastructureModels
using JuMP
using Ipopt
using Memento
using Gurobi




ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)
gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)


function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    PowerModelsMCDC.process_additional_data!(mp_data)
    for (c,conv) in mp_data["convdc"]
        conv["transformer"]=0
        conv["filter"]=0
        conv["reactor"]=0
        conv["LossA"]=0
        conv["LossB"]=0
        conv["LossCrec"]=0
        conv["LossCinv"]=0
    end

    # for (c,bn) in mp_data["branchdc"]
    #     bn["line_confi"]=1
    # end

    PowerModelsMCDC._make_multiconductor_new!(mp_data)
    return mp_data
end

datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")



file="./test/data/matacdc_scripts/case5_2grids_MC.m"

dc_data= PowerModels.parse_file(file)
_PMACDC.process_additional_data!(dc_data)

for (c,conv) in dc_data["convdc"]
    conv["transformer"]=0
    conv["filter"]=0
    conv["reactor"]=0
    conv["LossA"]=0
    conv["LossB"]=0
    conv["LossCrec"]=0
    conv["LossCinv"]=0
end


s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.DCPPowerModel, gurobi_solver, setting = s)

result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.DCPPowerModel, gurobi_solver, setting = s)
#
# result_mcdc["solution"]["convdc"]["1"]["pconv"][1]+result_mcdc["solution"]["convdc"]["1"]["pdc"][1]+result_mcdc["solution"]["convdc"]["1"]["pdcg"][1]
# result_mcdc["solution"]["convdc"]["2"]["pconv"][1]+result_mcdc["solution"]["convdc"]["2"]["pdc"][1]+result_mcdc["solution"]["convdc"]["2"]["pdcg"][1]
# result_mcdc["solution"]["convdc"]["3"]["pconv"][1]+result_mcdc["solution"]["convdc"]["3"]["pdc"][1]+result_mcdc["solution"]["convdc"]["3"]["pdcg"][1]
#
# result_mcdc["solution"]["convdc"]["1"]["pconv"][2]+result_mcdc["solution"]["convdc"]["1"]["pdc"][2]+result_mcdc["solution"]["convdc"]["1"]["pdcg"][2]
#
for i in 1:5
    display(result_mcdc["solution"]["gen"]["$i"]["pg"])
end


for i in 1:3
     # display("power from grid to dc at converter $i")
     display("power pgrid at converter $i")
    display(result_acdc["solution"]["convdc"]["$i"]["pgrid"])
end
for i in 1:3
    display("flow of over dc branch $i")
    display(result_mcdc["solution"]["branchdc"]["$i"])
end

# for i in 1:3
#     j=1
#     display(result_mcdc["solution"]["convdc"]["$i"]["pconv"][j]+result_mcdc["solution"]["convdc"]["$i"]["pdc"][j]+result_mcdc["solution"]["convdc"]["$i"]["pdcg"][j])
# end

# datadc_new["branchdc"]["3"]["confi"]
# datadc_new["branchdc"]["3"]["conductors"]
# datadc_new["convdc"]["1"]["acrated"]
# datadc_new["convdc"]["1"]["Pacrated"]
# println(datadc_new["convdc"]["1"])
#
# haskey(data11["branchdc"]["1"], "confi")
#
# for (i,j) in datadc_new["branchdc"]["1"]
#     println(i)
#     println("gap1")
#     # println(j)
#     # println("gap2")
#     break
# end
