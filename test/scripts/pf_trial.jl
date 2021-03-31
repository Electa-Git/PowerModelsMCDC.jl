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


# function build_mc_data!(base_data)
#     # function build_mc_data!(base_data)
#     mp_data = PowerModels.parse_file(base_data)
#     PowerModelsMCDC.process_additional_data!(mp_data)
#     for (c,conv) in mp_data["convdc"]
#         conv["transformer"]=0
#         conv["filter"]=0
#         conv["reactor"]=0
#         conv["LossA"]=0
#         conv["LossB"]=0
#         conv["LossCrec"]=0
#         conv["LossCinv"]=0
#
#     end
#
#     # for (c,bn) in mp_data["branchdc"]
#     #     bn["line_confi"]=1
#     # end
#     # _PD.make_multiconductor!(mp_data, conductors)
#     PowerModelsMCDC._make_multiconductor_new!(mp_data)
#     for (i,busdc) in mp_data["busdc"]
#         busdc["Vdcmax"][1]=1.1
#         busdc["Vdcmin"][1]=0.9
#         busdc["Vdcmax"][2]=-0.9
#         busdc["Vdcmin"][2]=-1.1
#         busdc["Vdcmax"][3]=0.1
#         busdc["Vdcmin"][3]=-0.1
#     end
#
#             # sepoints
#     for (c,conv) in mp_data["convdc"]
#
#     end
#     # Adjusting line limits
#     for (c,bn) in mp_data["branchdc"]
#         if bn["line_confi"]==2
#             bn["rateA"]=bn["rateA"]/2
#             bn["rateB"]=bn["rateB"]/2
#             bn["rateC"]=bn["rateC"]/2
#             bn["r"]=bn["r"]/2
#         end
#         metalic_cond_number= bn["conductors"]
#         bn["rateA"][metalic_cond_number]=bn["rateA"][metalic_cond_number]*0.1
#         bn["rateB"][metalic_cond_number]=bn["rateB"][metalic_cond_number]*0.1
#         bn["rateC"][metalic_cond_number]=bn["rateC"][metalic_cond_number]*0.1
#         bn["r"][metalic_cond_number]=bn["return_z"]
#     end
#
#       # Adjusting conveter limits
#       for (c,conv) in mp_data["convdc"]
#          if conv["conv_confi"]==2
#              conv["Pacmax"]=conv["Pacmax"]/2
#              conv["Pacmin"]=conv["Pacmin"]/2
#              conv["Pacrated"]=conv["Pacrated"]/2
#          end
#       end
#     return mp_data
# end

function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)

    for (c,bn) in mp_data["branchdc"]
        if bn["line_confi"]==1
            bn["connect_at"]=2
            # bn["line_confi"]=2
        end
    end
    for (c,conv) in mp_data["convdc"]
        display("configuration of $c is")
        display(conv["conv_confi"])
        if conv["conv_confi"]==1
            conv["connect_at"]=2
            # conv["conv_confi"]=2
        end
        conv["ground_type"]=0
    end

    for (c,conv) in mp_data["convdc"]
        # conv["transformer"]=0
        # conv["filter"]=0
        # conv["reactor"]=0
        conv["LossA"]=0
        conv["LossB"]=0
        conv["LossCrec"]=0
        conv["LossCinv"]=0
    end

    PowerModelsMCDC.process_additional_data!(mp_data)
    PowerModelsMCDC._make_multiconductor_new!(mp_data)
    # Adjusting line limits
    for (c,bn) in mp_data["branchdc"]
        if bn["line_confi"]==2
            bn["rateA"]=bn["rateA"]/2
            bn["rateB"]=bn["rateB"]/2
            bn["rateC"]=bn["rateC"]/2
            bn["r"]=bn["r"]/2
        end
        metalic_cond_number= bn["conductors"]
        bn["rateA"][metalic_cond_number]=bn["rateA"][metalic_cond_number]*0.1
        bn["rateB"][metalic_cond_number]=bn["rateB"][metalic_cond_number]*0.1
        bn["rateC"][metalic_cond_number]=bn["rateC"][metalic_cond_number]*0.1
        bn["r"][metalic_cond_number]=bn["return_z"]
    end

      # Adjusting conveter limits
      for (c,conv) in mp_data["convdc"]
         if conv["conv_confi"]==2
             conv["Pacmax"]=conv["Pacmax"]/2
             conv["Pacmin"]=conv["Pacmin"]/2
             conv["Pacrated"]=conv["Pacrated"]/2

             # adjust conv setpoints
             conv["P_g"]=conv["P_g"]/2
             display("for conv $c")
             display(conv["P_g"])
             conv["Q_g"]=conv["Q_g"]/2
             conv["Vdcset"][2]= -conv["Vdcset"][2]
             conv["Vdcset"]
         end
         if conv["conv_confi"]==1 && conv["connect_at"]==2
             conv["Vdcset"]=-conv["Vdcset"]
             display(conv["Vdcset"])
         end

      end
    return mp_data
end

datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")

for (c,conv) in datadc_new["convdc"]
    # display(conv["Q_g"])/
    display(c)
    display(conv["index"])
end

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
# result_mcdc = PowerModelsMCDC.run_mcdcpf(datadc_new, _PM.DCPPowerModel, gurobi_solver, setting = s)
result_mcdc = PowerModelsMCDC.run_mcdcpf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

result_acdc = _PMACDC.run_acdcpf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting = s)
result_acdc = _PMACDC.run_acdcpf(dc_data, _PM.DCPPowerModel, ipopt_solver, setting = s)

for i in 1:5
    display(result_acdc["solution"]["gen"]["$i"]["pg"])
end
# #
#
# for i in 1:3
#      # display("power from grid to dc at converter $i")
#      display("power pconv at converter $i")
#     display(result_acdc["solution"]["convdc"]["$i"]["pconv"])
# # end
# for i in 1:3
#     display("flow of over dc branch $i")
#     display(result_mcdc["solution"]["branchdc"]["$i"])
# end
for (i,branch) in result_mcdc["solution"]["branchdc"]
    flow_from=branch["pf"]
    flow_to=branch["pt"]
    display("$i, $flow_from, $flow_to")
end

for (i,bus) in result_mcdc["solution"]["busdc"]
    vm=bus["vm"]
    # flow_to=branch["pt"]
    display("$i, $vm")
end
