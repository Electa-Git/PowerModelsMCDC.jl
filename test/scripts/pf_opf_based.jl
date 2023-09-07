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
# file="./test/data/matacdc_scripts/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts/case5_2grids_MC.m"
# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf.m"
file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf_1BP.m"


# datadc_new = build_mc_data!(file)
# datadc_new = build_mc_data!("./test/data/matacdc_scripts_pf/3grids_MC.m")
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)

data = PowerModels.parse_file(file)
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
    if cv=="3"
        # "to introduce change in conv", "$cv")
        display(convdc["P_g"])
        convdc["P_g"]=1.1*convdc["P_g"]
    end

end
for (bd, busdc) in data["busdc"]
    busdc["vm"] = resultAC["solution"]["busdc"][bd]["vm"]
end
for (b, bus) in data["bus"]
    bus["vm"] = resultAC["solution"]["bus"][b]["vm"]
    bus["va"] = resultAC["solution"]["bus"][b]["va"] * 180 / pi
end

resultAC_pf = _PMACDC.run_acdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)
result_mcdc_pf = PowerModelsMCDC.solve_mcdcpf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)

data = PowerModelsMCDC.parse_file(file)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = result_mcdc_opf["solution"]["gen"][g]["pg"]
    gen["qg"] = result_mcdc_opf["solution"]["gen"][g]["qg"]
    gen["vg"] = result_mcdc_opf["solution"]["bus"]["$bus"]["vm"]
end
for (cv, convdc) in data["convdc"]
    busdc = convdc["busdc_i"]
    if convdc["conv_confi"] == 1 && convdc["connect_at"] == 2
        convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][2]
        # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
    else
        convdc["Vdcset"] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"]                # display(convdc["Vdcset"])
    end


    convdc["Q_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["qgrid"]
    convdc["P_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["pgrid"]
    
    # "to introduce change"
    if cv=="5"
        # "to introduce change in conv", "$cv")
        display(convdc["P_g"])
        convdc["P_g"]=1*convdc["P_g"]
    end
    # display("p and v setting")
    # display(convdc["P_g"])
    # display(convdc["Vdcset"])
end

for (bd, busdc) in data["busdc"]
    busdc["vm"] = result_mcdc_opf["solution"]["busdc"][bd]["vm"]

end

for (b, bus) in data["bus"]
    bus["vm"] = result_mcdc_opf["solution"]["bus"][b]["vm"]
    bus["va"] = result_mcdc_opf["solution"]["bus"][b]["va"] * 180 / pi

end

result_mcdc_opf1 = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
result_mcdc_pf1 = PowerModelsMCDC.solve_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)

# for (cv, convdc) in data["convdc"]
#     a=convdc["P_g"]
#     b=convdc["Q_g"]
#     # println("$cv", "$a", "$b") 
#     display(convdc["P_g"], convdc["P_g"])
# end



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
# result_mcdc_pf2 = PowerModelsMCDC.solve_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
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
# result_mcdc_pf3 = PowerModelsMCDC.solve_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)


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

# println("termination status of the acdc opf is:", resultAC["termination_status"])
# println("termination status of the acdc pf is:", resultAC_pf["termination_status"])
# println("Objective value of the ac opf is:", resultAC["objective"])
# println("Objective value of the ac pf is:", resultAC_pf["objective"])

# println("termination status of the opf is:", result_mcdc_opf["termination_status"])
# println("termination status of the pf is:", result_mcdc_pf["termination_status"])
# println("Objective value of the opf is:", result_mcdc_opf["objective"])
# println("Objective value of the pf is:", result_mcdc_pf["objective"])
println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])

println(".....conv....")
println(".....pgrid....")
for (i,conv) in result_mcdc_opf1["solution"]["convdc"]
     # display("power from grid to dc at converter $i")
     a= conv["pgrid"]
    display("$i, $a")
end

println("DC bus Vm OPF")
for (i,dcbus) in result_mcdc_opf1["solution"]["bus"]
    b=dcbus["vm"]
    display("$i, $b")
end

println("DC bus Vm pf")
for (i,dcbus) in result_mcdc_pf1["solution"]["bus"]
    b=dcbus["vm"]
    display("$i, $b")
end




_PM.component_table(result_mcdc_opf1["solution"], "bus", ["va"])
_PM.component_table(result_mcdc_pf1["solution"], "bus", ["va"])
[_PM.component_table(result_mcdc_opf1["solution"], "busdc", ["vm"]) _PM.component_table(result_mcdc_pf1["solution"], "busdc", ["vm"])]
[_PM.component_table(result_mcdc_opf1["solution"], "branchdc", ["i_from"]) _PM.component_table(result_mcdc_pf1["solution"], "branchdc", ["i_from"])]
[_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pgrid"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pgrid"])]
[_PM.component_table(result_mcdc_opf1["solution"], "gen", ["pg"]) _PM.component_table(result_mcdc_pf1["solution"], "gen", ["pg"])]

# _PM.component_table(result_mcdc_pf1["solution"], "gen", ["pg"])

[_PM.component_table(resultAC["solution"], "bus", ["va"]) _PM.component_table(resultAC_pf["solution"], "bus", ["va"])]
[_PM.component_table(resultAC["solution"], "gen", ["pg"]) _PM.component_table(resultAC_pf["solution"], "gen", ["pg"])]
[_PM.component_table(resultAC["solution"], "convdc", ["pgrid"]) _PM.component_table(resultAC_pf["solution"], "convdc", ["pgrid"])]

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
