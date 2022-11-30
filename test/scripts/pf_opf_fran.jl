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
using Cbc
using Juniper
using AmplNLWriter
using Couenne_jll
# ,print_level=1
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-9,print_level=1)
gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)

function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)
    #changing the connection point

       for (c,bn) in mp_data["branchdc"]
           # if bn["line_confi"]==1
           #     bn["connect_at"]=2
           #     # bn["line_confi"]=2
           # end
       end
       for (c,conv) in mp_data["convdc"]
           # display("configuration of $c is")
           # display(conv["conv_confi"])
           # if conv["conv_confi"]==1
           #     conv["connect_at"]=2
           #     # conv["conv_confi"]=2
           #     # conv["ground_type"]=0
           # end
           # conv["ground_type"]=1
           if conv["ground_type"]== 1 #or 0
               conv["ground_z"]=0.5
           end

       end

       #making lossless conv paramteres
     for (c,conv) in mp_data["convdc"]
        # conv["transformer"]=0
        # conv["filter"]=0
        # conv["reactor"]=0
        # conv["LossA"]=0
        # conv["LossB"]=0
        # conv["LossCrec"]=0
        # conv["LossCinv"]=0
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
        display(bn["r"][metalic_cond_number])

        bn["return_z"]=0.001384 # adjust metallic resistance
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
         busdc["Vdcmax"][3]=0.1
         busdc["Vdcmin"][3]=-0.1
         busdc["Vdcmax"][2]=-0.9
         busdc["Vdcmin"][2]=-1.1
      end
    return mp_data
end
function build_mc_data_pf_ac!(base_data)
    mp_data=base_data
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
        # bn["rateA"][metalic_cond_number]=bn["rateA"][metalic_cond_number]*0.1
        # bn["rateB"][metalic_cond_number]=bn["rateB"][metalic_cond_number]*0.1
        # bn["rateC"][metalic_cond_number]=bn["rateC"][metalic_cond_number]*0.1

        bn["return_z"]=0.5 # adjust metallic resistance
        # bn["r"][metalic_cond_number]=bn["return_z"]
        display(bn["r"][metalic_cond_number])
        bn["r"][metalic_cond_number]=0.5
    end

      # Adjusting conveter limits
      for (c,conv) in mp_data["convdc"]
         if conv["conv_confi"]==2
             conv["Pacmax"]=conv["Pacmax"]/2
             conv["Pacmin"]=conv["Pacmin"]/2
             conv["Pacrated"]=conv["Pacrated"]/2
             conv["Vdcset"][2]= -conv["Vdcset"][1]
             conv["P_g"]=conv["P_g"]/2
         end
         if conv["conv_confi"]==1
             conv["connect_at"]==2
             conv["Vdcset"][1]= -conv["Vdcset"][1]
         end
      end
      # Adjusting metallic return bus voltage limits
      for (i,busdc) in mp_data["busdc"]
         busdc["Vdcmax"][3]=0.1
         busdc["Vdcmin"][3]=-0.1
         busdc["Vdcmax"][2]=-0.9
         busdc["Vdcmin"][2]=-1.1
      end

    return mp_data
end

# file="./test/data/matacdc_scripts/case5_2grids_MC.m"
# file="./test/data/matacdc_scripts/case67mcdc_scopf.m"
file="./test/data/matacdc_scripts/fran_bipolarlink_testcase_case1.m"

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting = s)

data=build_mc_data!(file)
resultMC_opf = PowerModelsMCDC.run_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
# file="./test/data/matacdc_scripts/case5_2grids_MC.m"

# data= PowerModels.parse_file(file)
# PowerModelsMCDC.process_additional_data!(data)
#
# for (g, gen) in data["gen"]
#     bus = gen["gen_bus"]
#     gen["pg"] = resultAC["solution"]["gen"][g]["pg"]
#     gen["qg"] = resultAC["solution"]["gen"][g]["qg"]
#     gen["vg"] = resultAC["solution"]["bus"]["$bus"]["vm"]
# end
# for (cv, convdc) in data["convdc"]
#             busdc = convdc["busdc_i"]
#             convdc["Vdcset"] = resultAC["solution"]["busdc"]["$busdc"]["vm"]
#             convdc["Q_g"] = -resultAC["solution"]["convdc"]["$busdc"]["qgrid"]
#             convdc["P_g"] = -resultAC["solution"]["convdc"]["$busdc"]["pgrid"]
#             display(convdc["busdc_i"])
#             display(resultAC["solution"]["convdc"]["$busdc"]["qconv"])
#
# end
# for (bd, busdc) in data["busdc"]
#     busdc["vm"] = resultAC["solution"]["busdc"][bd]["vm"]
# end
# for (b, bus) in data["bus"]
#     bus["vm"] = resultAC["solution"]["bus"][b]["vm"]
#     bus["va"] = resultAC["solution"]["bus"][b]["va"] * 180/pi
# end
#
# resultAC_pf = _PMACDC.run_acdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
#
# data1= build_mc_data_pf_ac!(data)
# # data3= build_mc_data!(file)
#
# resultMC_pf = PowerModelsMCDC.run_mcdcpf(data1, _PM.ACPPowerModel, ipopt_solver, setting = s)
# println("termination status of the pf is:", resultMC_pf["termination_status"])
#
# for (bd, busdc) in data["busdc"]
#     a=busdc["vm"]
#     b= resultAC["solution"]["busdc"][bd]["vm"]
#     c=resultMC_pf["solution"]["busdc"][bd]["vm"]
#     display("$bd, $b, $c")
#     # display("$bd, $c")
#
# end

println("..objective value opf =", resultAC["objective"])
 # resultAC["objective"]

println(".....Pg opf....")
for (i,gen) in resultMC_opf["solution"]["gen"]
    a= gen["pg"]
    b= gen["qg"]
   display("$i, $a, $b")
end

println(".....AC bus volatage opf....")
for (i,bus) in resultMC_opf["solution"]["bus"]
    a= bus["vm"]
    b= bus["va"]
   display("$i, $a,$b")
end

println("..... ac brach flow opf....")
for (i,conv) in resultMC_opf["solution"]["branch"]
     a= conv["pt"]
     b= conv["qt"]
    display("$i, $a, $b")
end

println(".....pconv, qconv opf....")
for (i,conv) in resultMC_opf["solution"]["convdc"]
     a= conv["pconv"]
     b= conv["qconv"]
    display("$i, $a, $b")
end

println(".....pconv, pdc opf....")
for (i,conv) in resultMC_opf["solution"]["convdc"]
     a= conv["iconv"]
     b= conv["iconv_dc"]
     c= conv["iconv_dcg"]
     d= conv["iconv_dcg_shunt"]
    display("$i, $a, $b, $c, $d")
end


println("..... dc bus voltages opf....")
for (i,conv) in resultMC_opf["solution"]["busdc"]
     a= conv["vm"]
    display("$i, $a")
end

println("..... dc brach flow opf....")
for (i,conv) in resultMC_opf["solution"]["branchdc"]
     a= conv["i_from"]
    display("$i, $a")
end


# println(".....mcdc pconv opf....")
# for (i,conv) in resultMC_opf["solution"]["convdc"]
#      a= conv["pconv"]
#     display("$i, $a")
# end

# println(".....mcdc Pg opf....")
# for (i,conv) in resultMC_opf["solution"]["gen"]
#      a= conv["pg"]
#     display("$i, $a")
# end

# println("..... mcdc ac brach flow opf....")
# for (i,conv) in resultMC_opf["solution"]["branch"]
#      a= conv["pt"]
#     display("$i, $a")
# end
#
# println("..... mcdc dc brach flow opf....")
# for (i,conv) in resultMC_opf["solution"]["branchdc"]
#      a= conv["i_from"]
#     display("$i, $a")
# end

# println(".....pdc pf....")
# for (i,conv) in resultMC_pf["solution"]["convdc"]
#      a= conv["pdc"]
#     display("$i, $a")
# end

# for (bd, busdc) in data["busdc"]
#     a=busdc["vm"]
#     b= resultAC["solution"]["busdc"][bd]["vm"]
#     c=resultMC_pf["solution"]["busdc"][bd]["vm"]
#     display("$bd, $b, $c")
#     # display("$bd, $c")
# end
