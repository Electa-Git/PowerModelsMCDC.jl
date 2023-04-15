# chandra pf branch check 
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
# using Gurobi
using Cbc
using Juniper

 # print_level=1
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6,print_level=1)
# gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)

# couenne_solver=JuMP.with_optimizer(“C:/Users/mayar.madboly/Downloads/couenne-win64.exe”, print_level =0)

# ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=1)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer)
juniper = JuMP.with_optimizer(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt_solver)

function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)

  

       #making lossless conv paramteres and impedances
     for (c,conv) in mp_data["convdc"]
        # conv["transformer"]=0
        # conv["filter"]=0
        # conv["reactor"]=0
        # conv["LossA"]=0
        # conv["LossB"]=0
        # conv["LossCrec"]=0
        # conv["LossCinv"]=0
        if conv["conv_confi"]==2
            conv["rtf"]=2*conv["rtf"]
            conv["xtf"]=2*conv["xtf"]
            conv["bf"]=0.5*conv["bf"]
            conv["rc"]=2*conv["rc"]
            conv["xc"]=2*conv["xc"]
            conv["LossB"]=conv["LossB"]
            conv["LossA"]=0.5*conv["LossA"]
            conv["LossCrec"]=2*conv["LossCrec"]
            conv["LossCinv"]=2*conv["LossCinv"]
        end
           # transformer tm    filter
    end

    PowerModelsMCDC.process_additional_data!(mp_data)
    PowerModelsMCDC._make_multiconductor_new!(mp_data)
    # Adjusting line limits
    for (c,bn) in mp_data["branchdc"]
        if bn["line_confi"]==2
            bn["rateA"]=bn["rateA"]/2
            bn["rateB"]=bn["rateB"]/2
            bn["rateC"]=bn["rateC"]/2
            # bn["r"]=bn["r"]/2
        end

        metalic_cond_number= bn["conductors"]
        # bn["return_z"]=0.052 # adjust metallic resistance
        bn["r"][metalic_cond_number]=bn["return_z"]

    end

      # Adjusting conveter limits
      for (c,conv) in mp_data["convdc"]
         if conv["conv_confi"]==2
             conv["Pacmax"]=conv["Pacmax"]/2
             conv["Pacmin"]=conv["Pacmin"]/2
             conv["Pacrated"]=conv["Pacrated"]/2
         end
      end
      # Adjusting metallic return bus voltage limits
      for (i,busdc) in mp_data["busdc"]
         busdc["Vdcmax"][3]=busdc["Vdcmax"][1]-1.0
         busdc["Vdcmin"][3]=-(1-busdc["Vdcmin"][1])
         busdc["Vdcmax"][2]=-busdc["Vdcmin"][1]
         busdc["Vdcmin"][2]=-busdc["Vdcmax"][1]
      end
    return mp_data
end

# file="./test/data/matacdc_scripts/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts/case39_mcdc.m"
# file="./test/data/matacdc_scripts/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts/case3120sp_mcdc.m"

file="./test/data/matacdc_scripts/case5_2grids_MC_pf.m"


datadc_new = build_mc_data!(file)
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/3grids_MC.m")
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
resultAC_opf = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting = s)

data= PowerModels.parse_file(file)
PowerModelsMCDC.process_additional_data!(data)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = resultAC["solution"]["gen"][g]["pg"]
    gen["qg"] = resultAC["solution"]["gen"][g]["qg"]
    gen["vg"] = resultAC["solution"]["bus"]["$bus"]["vm"]
end
for (cv, convdc) in data["convdc"]
            busdc = convdc["busdc_i"]
            convdc["Vdcset"] = resultAC["solution"]["busdc"]["$busdc"]["vm"]
            convdc["Q_g"] = -resultAC["solution"]["convdc"]["$busdc"]["qgrid"]
            convdc["P_g"] = -resultAC["solution"]["convdc"]["$busdc"]["pgrid"]
            display(convdc["busdc_i"])
            display(resultAC["solution"]["convdc"]["$busdc"]["qconv"])

end
for (bd, busdc) in data["busdc"]
    busdc["vm"] = resultAC["solution"]["busdc"][bd]["vm"]
end
for (b, bus) in data["bus"]
    bus["vm"] = resultAC["solution"]["bus"][b]["vm"]
    bus["va"] = resultAC["solution"]["bus"][b]["va"] * 180/pi
end

resultAC_pf = _PMACDC.run_acdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
result_mcdc_pf = PowerModelsMCDC.run_mcdcpf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

data = build_mc_data!(file)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = result_mcdc_opf["solution"]["gen"][g]["pg"]
    gen["qg"] = result_mcdc_opf["solution"]["gen"][g]["qg"]
    gen["vg"] = result_mcdc_opf["solution"]["bus"]["$bus"]["vm"]
end
for (cv, convdc) in data["convdc"]
            busdc = convdc["busdc_i"]
            if convdc["conv_confi"]==1 && convdc["connect_at"]==2
                convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][2]
                # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
            else
                    convdc["Vdcset"]= result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"]                # display(convdc["Vdcset"])
            end

             convdc["Q_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["qgrid"]
             convdc["P_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["pgrid"]
            
             #"to introduce change"
             if cv=="3"
                 # display("to introduce change in conv", "$cv")
                 # display(convdc["P_g"])
                 convdc["P_g"]=1*convdc["P_g"]
             end
            display("p and v setting")
            display(convdc["P_g"])
            display(convdc["Vdcset"])
end

for (bd, busdc) in data["busdc"]
    busdc["vm"] = result_mcdc_opf["solution"]["busdc"][bd]["vm"]

end

for (b, bus) in data["bus"]
    bus["vm"] = result_mcdc_opf["solution"]["bus"][b]["vm"]
    bus["va"] = result_mcdc_opf["solution"]["bus"][b]["va"] * 180/pi

end

result_mcdc_opf1 = PowerModelsMCDC.run_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
  result_mcdc_pf1 = PowerModelsMCDC.run_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)

# for (cv, convdc) in data["convdc"]
#             busdc = convdc["busdc_i"]
#             if convdc["conv_confi"]==1 && convdc["connect_at"]==2
#                 convdc["Vdcset"][1] = result_mcdc_opf1["solution"]["busdc"]["$busdc"]["vm"][2]
#                 # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
#             else
#                     convdc["Vdcset"]= result_mcdc_opf1["solution"]["busdc"]["$busdc"]["vm"]                # display(convdc["Vdcset"])
#             end
#
#              convdc["Q_g"] = -result_mcdc_opf1["solution"]["convdc"]["$cv"]["qgrid"]
#              convdc["P_g"] = -result_mcdc_opf1["solution"]["convdc"]["$cv"]["pgrid"]
# end
#
# result_mcdc_opf2 = PowerModelsMCDC.run_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
# result_mcdc_pf2 = PowerModelsMCDC.run_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
#
# for (cv, convdc) in data["convdc"]
#             busdc = convdc["busdc_i"]
#             if convdc["conv_confi"]==1 && convdc["connect_at"]==2
#                 convdc["Vdcset"][1] = result_mcdc_opf2["solution"]["busdc"]["$busdc"]["vm"][2]
#                 # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
#             else
#                     convdc["Vdcset"]= result_mcdc_opf2["solution"]["busdc"]["$busdc"]["vm"]                # display(convdc["Vdcset"])
#             end
#
#              convdc["Q_g"] = -result_mcdc_opf2["solution"]["convdc"]["$cv"]["qgrid"]
#              convdc["P_g"] = -result_mcdc_opf2["solution"]["convdc"]["$cv"]["pgrid"]
# end
#
# result_mcdc_opf3 = PowerModelsMCDC.run_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
# result_mcdc_pf3 = PowerModelsMCDC.run_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)



#
# #DC grid side
# for (i,dcbus) in result_mcdc_pf["solution"]["busdc"]
#     b=dcbus["vm"]
#     display("$i, $b")
# end
#
#
#
# #conv
# for (i,conv) in result_mcdc_pf["solution"]["convdc"]
#      # display("power from grid to dc at converter $i")
#      a= conv["pgrid"]
#     display("$i, $a")
# end
#
# for (i,conv) in result_mcdc_pf["solution"]["convdc"]
#      a= conv["pdcg_shunt"]
#     display("$i, $a")
# end
#
# for (i,branch) in result_mcdc_pf["solution"]["branchdc"]
#     flow_from=branch["pf"]
#     flow_to=branch["pt"]
#     c=flow_from+flow_to
#     display("$i, $flow_from, $flow_to, $c")
#     # display("$i, $c")
#
# end
#
#
#
# #-------------------------------
# #"""comparison of opf and pf"""
# #-------------------------------
#
# # #
# for (g,gen) in data["gen"]
#         a= result_mcdc_opf["solution"]["gen"][g]["pg"]
#         b=result_mcdc_pf["solution"]["gen"][g]["pg"]
#         display("$g,$a, $b")
# end
# #
# # # sum(demand["pd"] for (d, demand) in data["load"] )
# # sum(gen["pg"] for (i,gen) in result_mcdc_opf["solution"]["gen"])
# # sum(gen["pg"] for (i,gen) in result_mcdc_pf["solution"]["gen"])
# #
# # for (i,gen) in result_mcdc_opf["solution"]["gen"]
# #     g=gen["pg"]
# #     display("$i, $g")
# # end
# #
# for (i,bus) in result_mcdc_opf["solution"]["bus"]
#     a=bus["va"]
#     b=bus["vm"]
#     c=result_mcdc_pf["solution"]["bus"]["$i"]["va"]
#     d=result_mcdc_pf["solution"]["bus"]["$i"]["vm"]
#     # display("$i, $b, $d, mag")
#     display("$i, $a, $c")
#
#     # display(a b)
# end
# #
# for (i,bus) in result_mcdc_opf["solution"]["busdc"]
#     a=result_mcdc_opf["solution"]["busdc"]["$i"]["vm"]
#     b=result_mcdc_pf["solution"]["busdc"]["$i"]["vm"]
#     display("$i, $a, $b")
# end
# #
# # for (i,conv) in result_mcdc_opf["solution"]["convdc"]
# #      # display("power from grid to dc at converter $i")
# #      a= conv["pgrid"]
# #     display("$i, $a")
# # end
# #
# for (i,conv) in result_mcdc_opf["solution"]["convdc"]
#      a= conv["pgrid"]
#      b=result_mcdc_pf["solution"]["convdc"]["$i"]["pgrid"]
#      display("$i, $a, $b")
# end
# #
# for (i,conv) in result_mcdc_opf["solution"]["convdc"]
#      a= conv["pdcg_shunt"]
#      b=result_mcdc_pf["solution"]["convdc"]["$i"]["pdcg_shunt"]
#      display("$i, $a, $b")
# end
# #
# for (i,conv) in result_mcdc_opf["solution"]["convdc"]
#      a= conv["pdcg"]
#      b=result_mcdc_pf["solution"]["convdc"]["$i"]["pdcg"]
#      display("$i, $a, $b")
#      # display("$i, $b")
# end
#
# # for (i,branch) in result_mcdc_opf["solution"]["branchdc"]
# #     a=branch["pf"]
# #     b=result_mcdc_pf["solution"]["branchdc"]["$i"]["pf"]
# #     display("$i, $a, $b")
# #
# #     # display("$i, $b")
# #
# # end
#
# # for (i,branch) in result_mcdc_opf["solution"]["branchdc"]
# #     flow_from=branch["pf"]
# #     flow_to=branch["pt"]
# #     display("$i, $flow_from, $flow_to")
# # end
#
#
# for (i,branch) in result_mcdc_opf["solution"]["branch"]
#     flow_from=branch["pf"]
#     flow_to=result_mcdc_pf["solution"]["branch"]["$i"]["pf"]
#     display("$i, $flow_from, $flow_to")
# end
#
# #
# for (i,conv) in data["convdc"]
#      a= conv["ground_type"]
#      # b=result_mcdc_pf["solution"]["convdc"]["$i"]["pgrid"]
#      # a=conv["ground_z"]
#      # a=conv["type_dc"]
#      display("$i, $a")
# end
#
# for (i,dcbranch) in data["branchdc"]
#      a= dcbranch["r"]
#      # b=result_mcdc_pf["solution"]["convdc"]["$i"]["pgrid"]
#      display("$i, $a")
# end
#
# for (i, branch) in result_mcdc_pf["solution"]["branch"]
#     flow_from=branch["pf"]
#     flow_to=branch["pt"]
#
#     a=result_mcdc_opf["solution"]["branch"]["$i"]["pf"]
#     b=flow_from
#      # b=result_mcdc_pf["solution"]["convdc"]["$i"]["pgrid"]
#      # display("$i, $flow_from, $flow_to")
#      display("$i, $a, $b")
# end
#
# println("termination status of the pf is:", result_mcdc_pf["termination_status"])
# #################
# #
# #
# for (g, gen) in data["gen"]
#     bus = gen["gen_bus"]
#     a1=gen["pg"]
#     b1= result_mcdc_opf["solution"]["gen"][g]["pg"]
#     a2=gen["qg"]
#     b2= result_mcdc_opf["solution"]["gen"][g]["qg"]
#     a3=gen["vg"]
#     b3= result_mcdc_opf["solution"]["bus"]["$bus"]["vm"]
#     # display("$g, $a1, $b1")
#     # display("$g, $a2, $b2")
#     display("$g, $a3, $b3")
# end
# # for (cv, convdc) in data["convdc"]
# #             busdc = convdc["busdc_i"]
# #             if convdc["conv_confi"]==1 && convdc["connect_at"]==2
# #                 convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][2]
# #                 # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
# #                 else
# #                     convdc["Vdcset"]= result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"]                # display(convdc["Vdcset"])
# #             end
# #
# #
# #             convdc["Q_g"] = -result_mcdc_opf["solution"]["convdc"]["$busdc"]["qgrid"]
# #             convdc["P_g"] = -result_mcdc_opf["solution"]["convdc"]["$busdc"]["pgrid"]
# #             # display(convdc["busdc_i"])
# #             # display(result_mcdc_opf["solution"]["convdc"]["$busdc"]["qconv"])
# #
# # end
# #
# # for (bd, busdc) in data["busdc"]
# #     a=busdc["vm"]
# #     b= result_mcdc_opf["solution"]["busdc"][bd]["vm"]
# #
# # end
#
# for (b, bus) in data["bus"]
#     a=bus["vm"]
#     b1= result_mcdc_opf["solution"]["bus"][b]["vm"]
#     c=bus["va"]
#     d= result_mcdc_opf["solution"]["bus"][b]["va"] * 180/pi
#     # display("$b, $a, $b1")
#     display("$b, $c, $d")
#
# end

println("termination status of the acdc opf is:", resultAC["termination_status"])
println("termination status of the acdc pf is:", resultAC_pf["termination_status"])
println("Objective value of the ac opf is:", resultAC["objective"])
println("Objective value of the ac pf is:", resultAC_pf["objective"])

println("termination status of the opf is:", result_mcdc_opf["termination_status"])
println("termination status of the pf is:", result_mcdc_pf["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf["objective"])
println("Objective value of the pf is:", result_mcdc_pf["objective"])

println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])

# println("termination status of the opf is:", result_mcdc_opf2["termination_status"])
# println("termination status of the pf is:", result_mcdc_pf2["termination_status"])
#
# println("Objective value of the opf is:", result_mcdc_opf2["objective"])
# println("Objective value of the pf is:", result_mcdc_pf2["objective"])
#
# println("termination status of the opf is:", result_mcdc_opf3["termination_status"])
# println("termination status of the pf is:", result_mcdc_pf3["termination_status"])
#
# println("Objective value of the opf is:", result_mcdc_opf3["objective"])
# println("Objective value of the pf is:", result_mcdc_pf3["objective"])
