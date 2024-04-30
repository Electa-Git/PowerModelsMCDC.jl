import PowerModels
const _PM = PowerModels
using PowerModelsMCDC
const _PMMCDC = PowerModelsMCDC
using PowerModelsACDC
const _PMACDC = PowerModelsACDC
using InfrastructureModels
const _IM = InfrastructureModels
using JuMP
using Ipopt
using Memento

# nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0, "bound_push"=>1e-4, "bound_frac"=>1e-4, "print_user_options"=>"yes")

# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf.m"
# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf_ngn.m"
# file = "./test/data/matacdc_scripts_pf/case5_2grids_MC_pf_1BP.m"

# file = "./test/data/matacdc_scripts_pf/Three_terminal_mcdc_pf.m"

file = "./test/data/matacdc_scripts_pf/benchmark_mcdc_5grids_pf.m"

########################## multiconductor model test (MCDC) OPF #########################

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)


########################## analyze results #########################

printstyled("MCDC OPF\n"; bold=true)
println(" termination status: ", result_mcdc_opf["termination_status"])
println("          objective: ", result_mcdc_opf["objective"])
println("         solve time: ", result_mcdc_opf["solve_time"])



# ########################## OPF based PF #########################
data = PowerModelsMCDC.parse_file(file)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = result_mcdc_opf["solution"]["gen"][g]["pg"]
    gen["qg"] = result_mcdc_opf["solution"]["gen"][g]["qg"]
    gen["vg"] = result_mcdc_opf["solution"]["bus"]["$bus"]["vm"]
end
for (cv, convdc) in data["convdc"]
    busdc = convdc["busdc_i"]
    busac = convdc["busac_i"]
    if convdc["conv_confi"] == 1 && convdc["connect_at"] == 2
        convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][2]-result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][3]
        # display(result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"])
    elseif  convdc["conv_confi"] == 1 && convdc["connect_at"] == 1
        convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][1]-result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][3]                # display(convdc["Vdcset"])
    else
        convdc["Vdcset"][1] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][1]-result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][3]                # display(convdc["Vdcset"])
        convdc["Vdcset"][2] = result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][2]-result_mcdc_opf["solution"]["busdc"]["$busdc"]["vm"][3]
    end
    convdc["Vacset"] = result_mcdc_opf["solution"]["bus"]["$busac"]["vm"]      # @show convdc["Vacset"]
    convdc["P_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["pgrid"]
    convdc["Q_g"] = -result_mcdc_opf["solution"]["convdc"]["$cv"]["qgrid"]

end 

for (bd, busdc) in data["busdc"]
    # busdc["vm"] = result_mcdc_opf["solution"]["busdc"][bd]["vm"]
    busdc["Vdc"] = result_mcdc_opf["solution"]["busdc"][bd]["vm"]
end

for (b, bus) in data["bus"]
    bus["vm"] = result_mcdc_opf["solution"]["bus"][b]["vm"]
    bus["va"] = result_mcdc_opf["solution"]["bus"][b]["va"] * 180 / pi
end

####### "to introduce change" ############
for (cv, convdc) in data["convdc"]
   
   if cv=="5" 
        # || cv=="2" 
        # "to introduce change in conv", "$cv")
        # display(convdc["P_g"])
        # convdc["P_g"]= 1.001*convdc["P_g"]
        # display(convdc["P_g"])
        # @show cv, convdc["Pdcset"]
        # convdc["Pdcset"]=1.05*convdc["Pdcset"]
        # @show convdc["Pdcset"]
        # display(convdc["Q_g"])
        # convdc["Q_g"]=2*convdc["Q_g"]

        # # display(convdc["Vdcset"])
        convdc["Vacset"]= 1.0
        convdc["Q_g"]= -0.1
        @show convdc["Vacset"], convdc["Q_g"]
        # @show convdc["Vdcset"]
        @show convdc["P_g"]        

    end

    # if cv=="2"
    #     convdc["Q_g"]=1000*convdc["Q_g"]
    # end 
    # display("p and v setting")
    # display(convdc["P_g"])
    # display(convdc["Vdcset"])
end 

# for (b, bus) in data["bus"]
#     if b== "10"
#         bus["vm"] = 1.0
#     end 
# end


result_mcdc_opf1 = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
sol = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

# data["convdc"]["4"]["status"]=0
result_mcdc_pf1 = PowerModelsMCDC.solve_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting=sol)


println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])



 [_PM.component_table(result_mcdc_opf1["solution"], "bus", ["va"]) _PM.component_table(result_mcdc_pf1["solution"], "bus", ["va"])]
 [_PM.component_table(result_mcdc_opf1["solution"], "bus", ["vm"]) _PM.component_table(result_mcdc_pf1["solution"], "bus", ["vm"])]
 [_PM.component_table(result_mcdc_opf1["solution"], "busdc", ["vm"]) _PM.component_table(result_mcdc_pf1["solution"], "busdc", ["vm"])]
#  [_PM.component_table(result_mcdc_opf1["solution"], "branchdc", ["i_from"]) _PM.component_table(result_mcdc_pf1["solution"], "branchdc", ["i_from"])]
# #  [_PM.component_table(result_mcdc_opf1["solution"], "branch", ["pf"]) _PM.component_table(result_mcdc_pf1["solution"], "branch", ["pf"])]
# #  [_PM.component_table(result_mcdc_opf1["solution"], "branch", ["pt"]) _PM.component_table(result_mcdc_pf1["solution"], "branch", ["pt"])]
 [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pgrid"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pgrid"])]
 [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["qgrid"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["qgrid"])]

# [_PM.component_table(result_mcdc_opf1["solution"], "gen", ["pg"]) _PM.component_table(result_mcdc_pf1["solution"], "gen", ["pg"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "gen", ["qg"]) _PM.component_table(result_mcdc_pf1["solution"], "gen", ["qg"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["iconv_dc"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["iconv_dc"])]
# [_PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pdc"]) _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pdc"])]

# # _PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pdc"])
# #  _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pdc"])

# #  _PM.component_table(result_mcdc_opf1["solution"], "convdc", ["pgrid"])
# #  _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["pgrid"])

# #  _PM.component_table(result_mcdc_opf1["solution"], "convdc", ["qgrid"])
# #  _PM.component_table(result_mcdc_pf1["solution"], "convdc", ["qgrid"])

# # # _PM.component_table(result_mcdc_opf["solution"], "gen", ["pg"])
# # # [_PM.component_table(resultAC["solution"], "bus", ["va"]) _PM.component_table(resultAC_pf["solution"], "bus", ["va"])]
# # # [_PM.component_table(resultAC["solution"], "gen", ["pg"]) _PM.component_table(resultAC_pf["solution"], "gen", ["pg"])]
# # # [_PM.component_table(resultAC["solution"], "convdc", ["pgrid"]) _PM.component_table(resultAC_pf["solution"], "convdc", ["pgrid"])]
# # # [_PM.component_table(resultAC["solution"], "busdc", ["vm"]) _PM.component_table(resultAC_pf["solution"], "busdc", ["vm"])]
# # # [_PM.component_table(resultAC["solution"], "branch", ["pf"]) _PM.component_table(resultAC["solution"], "branch", ["pf"])]


# result_mcdc_opf1["solution"]["busdc"]["2"]["vm"][2]- result_mcdc_o pf1["solution"]["busdc"]["2"]["vm"][3]
# result_mcdc_pf1["solution"]["busdc"]["2"]["vm"][2]- result_mcdc_pf1["solution"]["busdc"]["2"]["vm"][3]

# result_mcdc_pf1["solution"]["convdc"]["5"]["pgrid"]-result_mcdc_opf1["solution"]["convdc"]["5"]["pgrid"]

# ---------------------
# _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pdc"])
# _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pdcg"])
# -1*_PM.component_table(result_mcdc_opf["solution"], "convdc", ["pgrid"])
#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["qgrid"])
# #  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pconv"])
# #  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["qconv"])
#  _PM.component_table(result_mcdc_opf["solution"], "bus", ["va"]) 
# _PM.component_table(result_mcdc_opf["solution"], "bus", ["vm"])
# _PM.component_table(result_mcdc_opf["solution"], "busdc", ["vm"])

# 1060*_PM.component_table(result_mcdc_opf["solution"], "gen", ["pg"])
# _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pgrid"])-_PM.component_table(result_mcdc_opf["solution"], "convdc", ["pconv"])
# abc= _PM.component_table(result_mcdc_opf["solution"], "convdc", ["iconv"])[:,2]
