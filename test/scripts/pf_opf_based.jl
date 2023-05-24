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
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, tol=1e-6,print_level=1)
# gurobi_solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer)

# couenne_solver=JuMP.optimizer_with_attributes(“C:/Users/mayar.madboly/Downloads/couenne-win64.exe”, print_level =0)

# ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, tol=1e-4, print_level=1)
cbc_solver = JuMP.optimizer_with_attributes(Cbc.Optimizer)
juniper = JuMP.optimizer_with_attributes(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt_solver)

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

# file="./test/data/matacdc_scripts/case5_2grids_MC_pf.m"
file="./test/data/matacdc_scripts/case5_2grids_MC_pf_test.m"


datadc_new = build_mc_data!(file)
# datadc_new = build_mc_data!("./test/data/matacdc_scripts/3grids_MC.m")
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting = s)

data= PowerModels.parse_file(file)
PowerModelsMCDC.process_additional_data!(data)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = resultAC["solution"]["gen"][g]["pg"]
    gen["qg"] = resultAC["solution"]["gen"][g]["qg"]
    gen["vg"] = resultAC["solution"]["bus"]["$bus"]["vm"]
    if g=="4"
        gen["pg"]=9.05gen["pg"]
        display("change in gen setppoint")
        display(gen["pg"])
    end 
   

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
    #  if b=="7"
    #     bus["vm"]=0.95*bus["vm"]
    # end
end

resultAC_pf = _PMACDC.run_acdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
result_mcdc_pf = PowerModelsMCDC.solve_mcdcpf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

data = build_mc_data!(file)

for (g, gen) in data["gen"]
    bus = gen["gen_bus"]
    gen["pg"] = result_mcdc_opf["solution"]["gen"][g]["pg"]
    gen["qg"] = result_mcdc_opf["solution"]["gen"][g]["qg"]
    gen["vg"] = result_mcdc_opf["solution"]["bus"]["$bus"]["vm"]

    if g=="4"
         gen["pg"]=0.9*gen["pg"]
    end
    display("gen setpoint of gen $g are:")
    display(gen["pg"])
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
            
             #"to introduce change in conv setpoints"
             if cv=="4"
                 # display("to introduce change in conv", "$cv")
                 # display(convdc["P_g"])
                #  convdc["P_g"]=0.8*convdc["P_g"]
                #  convdc["Q_g"]=10*convdc["Q_g"]
                # display("conv 5 vdcset before change before ")
                # display(convdc["Vdcset"][1])
                convdc["Vdcset"][1]=0.9*convdc["Vdcset"][1]
                # display("conv 5 vdcset before change before ")
                # display(convdc["Vdcset"][1])
             end

            #"to introduce change in conv setpoints"
        

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

    if b=="7"
        # bus["vm"]=1.01*bus["vm"]
    end

end

# "to introduce changes setpoints"

# to introduce change in dc bus voltage setpoints
# for (bd, busdc) in data["busdc"]

#     if bd=="1"
#         # chaning negative terminal voltage of dc bus 1
#         busdc["vm"][2]=0.9*busdc["vm"][2]
#     end
# end

#"to introduce change in converter setpoints"
# for (cv, convdc) in data["convdc"]
#      #"to introduce change in conv setpoints"
#      if cv=="5"
#          # display("to introduce change in conv", "$cv")
#          # display(convdc["P_g"])
#         #  convdc["P_g"]=0.8*convdc["P_g"]
#          convdc["Q_g"]=10*convdc["Q_g"]
#      end
# end

result_mcdc_opf1 = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)
result_mcdc_pf1 = PowerModelsMCDC.solve_mcdcpf(data, _PM.ACPPowerModel, ipopt_solver, setting = s)



println("termination status of the acdc opf is:", resultAC["termination_status"])
println("termination status of the acdc pf is:", resultAC_pf["termination_status"])
println("Objective value of the ac opf is:", resultAC["objective"])
println("Objective value of the ac pf is:", resultAC_pf["objective"])

println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])
println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])
