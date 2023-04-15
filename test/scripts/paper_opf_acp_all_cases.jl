using LinearAlgebra
# using LinearAlgebra: I
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

# ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-8, print_level=1)
# gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

"This function should be taken inside the surce file"
function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)

    #changing the connection point
    #    for (c,bn) in mp_data["branchdc"]
    #        if bn["line_confi"]==1
    #            # bn["connect_at"]=2
    #            bn["line_confi"]=2
    #        end
    #        if c == "0"
    #            # display(bn["fbusdc"])
    #            # display(bn["tbusdc"])
    #            bn["connect_at"]=1
    #            bn["line_confi"]=1
    #        end
    #    end
       for (c,conv) in mp_data["convdc"]
           display("configuration of $c is")
           display(conv["conv_confi"])
        #    if conv["conv_confi"]==1
        #        # conv["connect_at"]=2
        #        conv["conv_confi"]=2
        #        # conv["ground_type"]=0
        #    end
           "for simulating a single pole outage"
        #    if c == "2"
        #        conv["conv_confi"]=1
        #         conv["connect_at"]=1
        #        # conv["ground_type"]=0
        #        conv["rtf"]=2*conv["rtf"]
        #        conv["xtf"]=2*conv["xtf"]
        #        conv["bf"]=0.5*conv["bf"]
        #        conv["rc"]=2*conv["rc"]
        #        conv["xc"]=2*conv["xc"]
        #        conv["LossB"]=conv["LossB"]
        #        conv["LossA"]=0.5*conv["LossA"]
        #        conv["LossCrec"]=2*conv["LossCrec"]
        #        conv["LossCinv"]=2*conv["LossCinv"]
        #    end

           if conv["ground_type"]== 1 #or 0
               conv["ground_z"]=0.5
           end
             # conv["ground_type"]=0
       end

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
        # bn["rateA"][metalic_cond_number]=bn["rateA"][metalic_cond_number]*0.1
        # bn["rateB"][metalic_cond_number]=bn["rateB"][metalic_cond_number]*0.1
        # bn["rateC"][metalic_cond_number]=bn["rateC"][metalic_cond_number]*0.1

        bn["return_z"]=0.052 # adjust metallic resistance
        bn["r"][metalic_cond_number]=bn["return_z"]
        # if bn["line_confi"]==1
        #     bn["return_z"]=0.052 # adjust metallic resistance
        #     bn["r"][metalic_cond_number]=bn["return_z"]
        # end

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

# file="./test/data/matacdc_scripts_opf_paper/balanced/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case39_mcdc.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts_opf_paper/balanced/case3120sp_mcdc.m"

# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case39_mcdc.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case67mcdc_scopf4.m"
# file="./test/data/matacdc_scripts_opf_paper/unbalanced/case3120sp_mcdc.m"

"power flow related experiments"
file="./test/data/matacdc_scripts/case5_2grids_MC_pf.m"

datadc_new = build_mc_data!(file)
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/3grids_MC.m")
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/4_case5_2grids_MC.m")

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

#--------------------------------------------------------------------------------------------------------
# file="./test/data/matacdc_scripts/case5_2grids_MC.m"
dc_data= PowerModels.parse_file(file)
_PMACDC.process_additional_data!(dc_data)
for (c,conv) in dc_data["convdc"]
    # conv["transformer"]=0
    # conv["filter"]=0
    # conv["reactor"]=0
    # conv["LossA"]=0
    # conv["LossB"]=0
    # conv["LossCrec"]=0
    # conv["LossCinv"]=0
end
result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting = s)

# for i in 1:5
#     display(result_acdc["solution"]["gen"]["$i"]["pg"])
# end



#############

println("termination status of the acdc_opf is:", result_acdc["termination_status"])
println(" Objective acdc_opf is:", result_acdc["objective"])
println(" solve time acdc_opf is:", result_acdc["solve_time"])

println("termination status of the mcdc_opf is:", result_mcdc["termination_status"])
println(" Objective mcdc_opf is:", result_mcdc["objective"])
println(" solve time mcdc_opf is:", result_mcdc["solve_time"])

#########

# N=100
# solve_time_dc=Dict([(l, Dict([("$i", 0.0000) for i in 1:4])) for l in 1:N])

# for k=1:N

#   result_mcdc = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
#   result_acdc = _PMACDC.run_acdcopf(dc_data, _PM.ACPPowerModel, ipopt_solver, setting = s)


#     #  solve_time_dc[k]["1"] = result_mcdc["termination_status"]
#      solve_time_dc[k]["2"] = result_mcdc["solve_time"]
#     #  solve_time_dc[k]["3"] = result_acdc["termination_status"]
#      solve_time_dc[k]["4"] = result_acdc["solve_time"]
     
# end

# avg_solvetime_mcdc= sum(solve_time_dc[k]["2"] for k in 1:N)/N
# avg_solvetime_acdc= sum(solve_time_dc[k]["4"] for k in 1:N)/N

# println(" Objective mcdc_opf is:", result_mcdc["objective"])
# println(" Objective acdc_opf is:", result_acdc["objective"])

# println(" avg_solvetime_mcdcf is:",avg_solvetime_mcdc)
# println(" avg_solvetime_acdcf is:",avg_solvetime_acdc)

# 0.55165  0.887  5.77  5.77