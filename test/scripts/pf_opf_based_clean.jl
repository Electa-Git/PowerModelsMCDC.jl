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
file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf.m"
# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf_1BP.m"


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
        # display(convdc["P_g"])
        convdc["P_g"]=1.1*convdc["P_g"]

        # display(convdc["Q_g"])
        # convdc["Q_g"]=1.1*convdc["Q_g"]
    
        # display(convdc["Vdcset"])
        # convdc["Vdcset"]=1.1*convdc["Vdcset"]
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


# println("termination status of the opf is:", result_mcdc_opf["termination_status"])
# println("termination status of the pf is:", result_mcdc_pf["termination_status"])
# println("Objective value of the opf is:", result_mcdc_opf["objective"])
# println("Objective value of the pf is:", result_mcdc_pf["objective"])
println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])

# println(".....conv....")
# println(".....pgrid....")
# for (i,conv) in result_mcdc_opf1["solution"]["convdc"]
#      # display("power from grid to dc at converter $i")
#      a= conv["pgrid"]
#     display("$i, $a")
# end

# println("DC bus Vm OPF")
# for (i,dcbus) in result_mcdc_opf1["solution"]["bus"]
#     b=dcbus["vm"]
#     display("$i, $b")
# end

# println("DC bus Vm pf")
# for (i,dcbus) in result_mcdc_pf1["solution"]["bus"]
#     b=dcbus["vm"]
#     display("$i, $b")
# end




# [_PM.component_table(result_mcdc_opf1["solution"], "bus", ["va"]) _PM.component_table(result_mcdc_pf1["solution"], "bus", ["va"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "bus", ["vm"]) _PM.component_table(result_mcdc_pf1["solution"], "bus", ["vm"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "busdc", ["vm"]) _PM.component_table(result_mcdc_pf1["solution"], "busdc", ["vm"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "branchdc", ["i_from"]) _PM.component_table(result_mcdc_pf1["solution"], "branchdc", ["i_from"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pgrid"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pgrid"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "gen", ["pg"]) _PM.component_table(result_mcdc_pf1["solution"], "gen", ["pg"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["iconv_dc"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["iconv_dc"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pdc"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pdc"])]

# # _PM.component_table(result_mcdc_pf1["solution"], "gen", ["pg"])

# [_PM.component_table(resultAC["solution"], "bus", ["va"]) _PM.component_table(resultAC_pf["solution"], "bus", ["va"])]
# [_PM.component_table(resultAC["solution"], "gen", ["pg"]) _PM.component_table(resultAC_pf["solution"], "gen", ["pg"])]
# [_PM.component_table(resultAC["solution"], "convdc", ["pgrid"]) _PM.component_table(resultAC_pf["solution"], "convdc", ["pgrid"])]
# [_PM.component_table(resultAC["solution"], "busdc", ["vm"]) _PM.component_table(resultAC_pf["solution"], "busdc", ["vm"])]


