#example of dcp formulation of the opf problem
import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import PowerModelsACDC as _PMACDC
using JuMP
using Ipopt

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
file = "./test/data/matacdc_scripts/case5_2grids_MC.m"

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.DCPPowerModel, ipopt_solver, setting=s)

nlp_optimizer = _PMMCDC.optimizer_with_attributes(
    Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0, "sb" => "yes"
)
result_dcp = _PMMCDC.solve_mcdcopf(file, _PM.DCPPowerModel, nlp_optimizer)

#--------------------------------------------------------------------------------------------------------
result_acdc = _PMACDC.run_acdcopf(file, _PM.DCPPowerModel, ipopt_solver, setting=s)

#############

println("termination status of the acdc_opf is:", result_acdc["termination_status"])
println(" Objective acdc_opf is:", result_acdc["objective"])
println(" solve time acdc_opf is:", result_acdc["solve_time"])

println("termination status of the mcdc_opf is:", result_mcdc["termination_status"])
println(" Objective mcdc_opf is:", result_mcdc["objective"])
println(" solve time mcdc_opf is:", result_mcdc["solve_time"])

############## "Keepin the following commented lines as it usefel for the user to analyse the results" ##############

# println("#######ACgrid side#######")
# println("generation")
# for (i,gen) in result_mcdc["solution"]["gen"]
#     g=gen["pg"]
#     display("$i, $g")
# end

# total_gen= sum(gen["pg"] for (i,gen) in result_mcdc["solution"]["gen"])
# println("toptal generation", total_gen)

# data = _PM.parse_file(file)
# total_load= sum(load["pd"] for (i,load) in data["load"])
# println("toptal generation", total_load)

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

# for (i,branch) in datadc_new["branchdc"]
#     r=branch["r"]
#     display("$i,$r")
# end

println(".....DC branch losses....")
# for (i,branch) in result_mcdc["solution"]["branchdc"]
#     flow_from=branch["pf"]
#     flow_to=branch["pt"]
#     c=flow_from+flow_to
#     # display("$i, $flow_from, $flow_to, $c")
#     display("$i, $c")
# end

# println("termination status of the opf is:", result_mcdc["termination_status"])
#
# println("AC branch flows")
# for (i,branch) in datadc_new["branchdc"]
#     r=branch["r"]
#     display("$i, $r")
# end

# println("...total system losses..")
# Tot_gen= sum(gen["pg"] for (i,gen) in result_mcdc["solution"]["gen"])
# tot_load=sum(load["pd"] for (i,load) in datadc_new["load"])
# tot_loss=Tot_gen-tot_load