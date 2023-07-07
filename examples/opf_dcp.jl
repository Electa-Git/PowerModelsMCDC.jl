# OPF problem, linear formulation

import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import HiGHS

lp_solver = _PMMCDC.optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false)
file = "./test/data/matacdc_scripts/case5_2grids_MC.m"

s = Dict("conv_losses_mp" => false)
result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.DCPPowerModel, lp_solver, setting=s)


## Comparison with PowerModelsACDC (single conductor model)

import PowerModelsACDC as _PMACDC

result_acdc = _PMACDC.run_acdcopf(file, _PM.DCPPowerModel, lp_solver, setting=s)

printstyled("Multiconductor OPF\n"; bold=true)
println(" termination status: ", result_mcdc["termination_status"])
println("          objective: ", result_mcdc["objective"])
println("         solve time: ", result_mcdc["solve_time"])

printstyled("\nSingle-conductor OPF\n"; bold=true)
println(" termination status: ", result_acdc["termination_status"])
println("          objective: ", result_acdc["objective"])
println("         solve time: ", result_acdc["solve_time"])


## Further analysis of results

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

# println(".....DC branch losses....")
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
