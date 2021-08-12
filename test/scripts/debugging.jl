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
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6,print_level=1)
gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)
# couenne_solver= JuMP.with_optimizer("Users/cjat/Downloads/couenne-osx/couenne.exe", print_level =0)
# couenne_solver= JuMP.with_optimizer("Users/cjat/Downloads/couenne-osx/couenne", print_level =0)

# () -> AmplNLWriter.Optimizer("bonmin")
# Ipopt_jll.amplexe
# couenne_solver= JuMP.with_optimizer(() ->AmplNLWriter.Optimizer(Couenne_jll.amplexe))
# using Ipopt_jll
# using AmplNLWriter
# couenne_solver= JuMP.with_optimizer(AmplNLWriter.Optimizer(Couenne_jll.amplexe))
# ipopt=() ->AmplNLWriter.Optimizer(Ipopt_jll.amplexe)
# cbc_solver = JuMP.with_optimizer(Cbc.Optimizer)
# juniper = JuMP.with_optimizer(Juniper.Optimizer, mip_solver=cbc_solver, nl_solver = ipopt_solver)

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
            bn["r"]=bn["r"]/2
        end
        metalic_cond_number= bn["conductors"]
        # bn["rateA"][metalic_cond_number]=bn["rateA"][metalic_cond_number]*0.1
        # bn["rateB"][metalic_cond_number]=bn["rateB"][metalic_cond_number]*0.1
        # bn["rateC"][metalic_cond_number]=bn["rateC"][metalic_cond_number]*0.1

        bn["return_z"]=0.5 # adjust metallic resistance
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

# datadc_new = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")
datadc_new = build_mc_data!("./test/data/matacdc_scripts/4_case5_2grids_MC.m")

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc_opf = PowerModelsMCDC.run_mcdcopf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)
result_mcdc_pf = PowerModelsMCDC.run_mcdcpf(datadc_new, _PM.ACPPowerModel, ipopt_solver, setting = s)

# data = build_mc_data!("./test/data/matacdc_scripts/case5_2grids_MC.m")
data = build_mc_data!("./test/data/matacdc_scripts/4_case5_2grids_MC.m")

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

println("termination status of the opf is:", result_mcdc_opf["termination_status"])
println("termination status of the pf is:", result_mcdc_pf["termination_status"])

println("Objective value of the opf is:", result_mcdc_opf["objective"])
println("Objective value of the pf is:", result_mcdc_pf["objective"])

println("termination status of the opf is:", result_mcdc_opf1["termination_status"])
println("termination status of the pf is:", result_mcdc_pf1["termination_status"])

println("Objective value of the opf is:", result_mcdc_opf1["objective"])
println("Objective value of the pf is:", result_mcdc_pf1["objective"])

println(".....dc bus voltages opf and pf....")

for (bd, busdc) in data["busdc"]
    a=busdc["vm"]
    b= result_mcdc_opf1["solution"]["busdc"][bd]["vm"]
    c=result_mcdc_pf1["solution"]["busdc"][bd]["vm"]
    display("$bd, $b, $c")
    # display("$bd, $c")

end

for (bd, busdc) in data["gen"]
    # a=busdc["vm"]
    b= result_mcdc_opf1["solution"]["gen"]["$bd"]["pg"]
    c=result_mcdc_pf1["solution"]["gen"]["$bd"]["pg"]
    display("$bd, $b, $c")
    # display("$bd, $c")

end

for (bd, bus) in data["bus"]
    # a=bus["va"]
    b= result_mcdc_opf1["solution"]["bus"][bd]["va"]
    c=result_mcdc_pf1["solution"]["bus"][bd]["va"]
    display("$bd, $b, $c")
    # display("$bd, $c")
end

println(".....pdc opf....")
for (i,conv) in result_mcdc_opf1["solution"]["convdc"]
     a= conv["pdc"]
    display("$i, $a")
end

println(".....pdc pf....")
for (i,conv) in result_mcdc_pf1["solution"]["convdc"]
     a= conv["pdc"]
    display("$i, $a")
end

println(".....pgrid opf....")
for (i,conv) in result_mcdc_opf1["solution"]["convdc"]
     a= conv["pgrid"]
    display("$i, $a")
end

println(".....pgrid pf....")
for (i,conv) in result_mcdc_pf1["solution"]["convdc"]
     a= conv["pgrid"]
    display("$i, $a")
end
