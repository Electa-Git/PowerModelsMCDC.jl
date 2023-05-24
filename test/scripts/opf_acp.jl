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


# ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, tol=1e-8, print_level=1)
# gurobi_solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer)

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)


function build_mc_data!(base_data)
    mp_data = PowerModels.parse_file(base_data)

    #changing the connection point
       for (c,bn) in mp_data["branchdc"]
           # if bn["line_confi"]==1
           #     # bn["connect_at"]=2
           #     bn["line_confi"]=2
           # end
       end
       for (c,conv) in mp_data["convdc"]
           # display("configuration of $c is")
           # display(conv["conv_confi"])
           # if conv["conv_confi"]==1
           #     # conv["connect_at"]=2
           #     conv["conv_confi"]=2
           #     # conv["ground_type"]=0
           # end
           # if conv["ground_type"]== 1 #or 0
           #     conv["ground_z"]=0.5
           # end
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
         busdc["Vdcmax"][3]=0.1
         busdc["Vdcmin"][3]=-0.1
         busdc["Vdcmax"][2]=-0.9
         busdc["Vdcmin"][2]=-1.1
      end
    return mp_data
end

datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/3grids_MC.m")
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/4_case5_2grids_MC.m")


s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc = PowerModelsMCDC.solve_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

#--------------------------------------------------------------------------------------------------------
file="./test/data/matacdc_scripts/case5_2grids_MC.m"
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

# println("#######ACgrid side#######")
# println("generation")
# for (i,gen) in result_mcdc["solution"]["gen"]
#     g=gen["pg"]
#     display("$i, $g")
# end
# println("AC Bus Va and Vm")
# for (i,bus) in result_mcdc["solution"]["bus"]
#     a=bus["va"]
#     b=bus["vm"]
#     display("$i, $a, $b")
#     # display(a b)
# end

# println("AC branch flows")
# for (i,branch) in result_mcdc["solution"]["branch"]
#     flow_from=branch["pf"]
#     flow_to=branch["pt"]
#     display("$i, $flow_from, $flow_to")
# end



# println("###DC grid side###")
# println("DC bus Vm")
# for (i,dcbus) in result_mcdc["solution"]["busdc"]
#     b=dcbus["vm"]
#     display("$i, $b")
# end


# println(".....conv....")
# println(".....pgrid....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      # display("power from grid to dc at converter $i")
#      a= conv["pgrid"]
#     display("$i, $a")
# end

# println(".....pdc....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      a= conv["pdc"]
#     display("$i, $a")
# end

# println(".....pdcg....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      a= conv["pdcg"]
#     display("$i, $a")
# end

# println(".....pdcg_shunt....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      a= conv["pdcg_shunt"]
#     display("$i, $a")
# end

# println(".....iconv_dc....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      a= conv["iconv_dc"]
#      display("$i, $a")
# end

# println(".....iconv_dcg_shunt....")
# for (i,conv) in result_mcdc["solution"]["convdc"]
#      a= conv["iconv_dcg_shunt"]
#      display("$i, $a")
# end
# println(".....conv ground status....")
# for (i,conv) in datadc_new["convdc"]
#         a=conv["ground_type"]
#         b=conv["ground_z"]
#         display("$a, $b")
# end

# println(".....DC branch flows....")
# for (i,branch) in result_mcdc["solution"]["branchdc"]
#     flow_from=branch["i_from"]
#     flow_to=branch["i_to"]
#     display("$i, $flow_from, $flow_to")
# end

# # for (i,branch) in datadc_new["branchdc"]
# #     r=branch["r"]
# #     display("$i,$r")
# # end

# println(".....DC branch losses....")
# # for (i,branch) in result_mcdc["solution"]["branchdc"]
# #     flow_from=branch["pf"]
# #     flow_to=branch["pt"]
# #     c=flow_from+flow_to
# #     # display("$i, $flow_from, $flow_to, $c")
# #     display("$i, $c")
# # end

# # println("termination status of the opf is:", result_mcdc["termination_status"])
# #
# # println("AC branch flows")
# # for (i,branch) in datadc_new["branchdc"]
# #     r=branch["r"]
# #     display("$i, $r")
# # end

# # println("...total system losses..")
# # Tot_gen= sum(gen["pg"] for (i,gen) in result_mcdc["solution"]["gen"])
# # tot_load=sum(load["pd"] for (i,load) in datadc_new["load"])
# # tot_loss=Tot_gen-tot_load

# "........pd[11] variation results....."
# N=10
# # vm_0= Dict([(l, Dict([(i, 0.0000) for (i, dcbus) in result_mcdc["solution"]["busdc"]])) for l in 1:N])

# vm_0= Dict([(l, Dict([("$i", 0.0000) for i in 1:4+2+3])) for l in 1:N])  # 4 for the neutraltermianl of the 4 dc buses, 2 for the objective and Pg5, 3 for the three converter neutral currents
# vm_term=Dict([(l, Dict()) for l in 1:N])
#  load_0=0.5

#  for (c,bn) in datadc_new["branchdc"]
#     metalic_cond_number= bn["conductors"]
#     bn["return_z"]=0.52 # adjust metallic resistance
#     bn["r"][metalic_cond_number]=bn["return_z"]
# end

# for k=1:N
#     for (i, load) in datadc_new["load"]
#         if load["load_bus"] == 11
#             load["pd"]= k*0.1*load_0
#         end
#     end

#   result_mcdc = PowerModelsMCDC.solve_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
#     for (i, dcbus) in result_mcdc["solution"]["busdc"]
#          b=dcbus["vm"][3]
#          vm_0[k]["$i"]= b
#      end
#      obj= result_mcdc["objective"]
#      pg5=result_mcdc["solution"]["gen"]["5"]["pg"]
#      # term=result_mcdc["termination_status"]
#      vm_0[k]["5"]= obj
#      vm_0[k]["6"]= pg5
#      # push!(vm_term[k], term)

#      vm_0[k]["7"]=result_mcdc["solution"]["convdc"]["1"]["iconv_dc"][3]
#      vm_0[k]["8"]=result_mcdc["solution"]["convdc"]["2"]["iconv_dc"][3]
#      vm_0[k]["9"]=result_mcdc["solution"]["convdc"]["3"]["iconv_dc"][2]
# end


# for (itr, bus) in vm_0
# # for k=1:N
#     a=bus["1"]
#     b=bus["2"]
#     c=bus["3"]
#     d=bus["4"]
#     obj=bus["5"]
#     pg5=bus["6"]
#     iconv_dc0_1= bus["7"]
#     iconv_dc0_2= bus["8"]
#     iconv_dc0_3= bus["9"]
#     display("$itr, $a, $b, $c, $d, $obj,$pg5, $iconv_dc0_1,$iconv_dc0_2,$iconv_dc0_3")
#     # display("$bus["1"], $bus["3"]")
#     # display("itr, bus["1"], bus["2"], bus["3"], bus["4"])
# end
# #

#  ".......rd0 variation results....."
# #
# # N=10
# # # vm_0= Dict([(l, Dict([(i, 0.0000) for (i, dcbus) in result_mcdc["solution"]["busdc"]])) for l in 1:N])
# #
# # vm_0= Dict([(l, Dict([("$i", 0.0000) for i in 1:4+2])) for l in 1:N])
# # vm_term=Dict([(l, Dict()) for l in 1:N])
# #  # load_0=0.5
# #
# # for k=1:N
# #     for (c,bn) in datadc_new["branchdc"]
# #         metalic_cond_number= bn["conductors"]
# #         bn["return_z"]=0.52 # adjust metallic resistance
# #         bn["r"][metalic_cond_number]=bn["return_z"]
# #         if bn["line_confi"]==1
# #             bn["r"][metalic_cond_number]=k*0.052
# #         end
# #     end
# #
# #   result_mcdc = PowerModelsMCDC.solve_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
# #     for (i, dcbus) in result_mcdc["solution"]["busdc"]
# #          b=dcbus["vm"][3]
# #          vm_0[k]["$i"]= b
# #      end
# #      obj= result_mcdc["objective"]
# #      pg5=result_mcdc["solution"]["gen"]["5"]["pg"]
# #      # term=result_mcdc["termination_status"]
# #      vm_0[k]["5"]= obj
# #      vm_0[k]["6"]= pg5
# #      # push!(vm_term[k], term)
# # end
# #
# #
# # for (itr, bus) in vm_0
# # # for k=1:N
# #     a=bus["1"]
# #     b=bus["2"]
# #     c=bus["3"]
# #     d=bus["4"]
# #     obj=bus["5"]
# #     pg5=bus["6"]
# #     display("$itr, $a, $b, $c, $d, $obj,$pg5")
# #     # display("$bus["1"], $bus["3"]")
# #     # display("itr, bus["1"], bus["2"], bus["3"], bus["4"])
# # end
# #
