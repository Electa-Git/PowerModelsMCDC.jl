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
using DataFrames
using CSV

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 1, "print_user_options" => "yes")

# file = "./test/data/planning /demogrid_case_1_bipolar.m"
# file = "./test/data/planning/demogrid_case_2_sym_monopolar_2GW.m"
# file = "./test/data/planning/demogrid_case_3_Asym_monopolar_2GW.m"

# file = "./test/data/planning/demogrid_case_4_sym_monopolar_1GW.m"
file = "./test/data/planning/demogrid_case_5_sym_monopolar_1GW_320.m"

# data = PowerModelsMCDC.parse_file(file);
# s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
# result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)

###################### import day-ahaed price and load data ==> base case #################
# data["branchdc"]["4"]["status"]=0
data = PowerModelsMCDC.parse_file(file);
#  data["convdc"]["4"]["status"]=0
#  data["convdc"]["1"]["ground_type"]=1
#  data["convdc"]["4"]["ground_type"]=0
#  data["convdc"]["8"]["ground_type"]=0
# for (i, busdc) in data["busdc"]
#     busdc["Vdcmax"][3] = 0.1
# end
using Statistics  # For calculating the mean

results = Dict{String,Vector{Float64}}()

# Specify the path to your CSV file
# file_path = "./test/data/planning/Day-ahead Prices_2023_UK.csv"
# file_path = "./test/data/planning/Day-ahead Prices_2023_BE.csv"
# file_path = "./test/data/planning/gen_and_load/Day-ahead Prices_2020BE.csv"

# file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean.csv"
file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"

df = CSV.read(file_path, DataFrame);
# #update generation prices and load data
# length( df[!,"1"])
# for i in 1:length( df[!,"1"])
i = 1
value_be = df[!, "1"][i]
value_dk = df[!, "2"][i]
value_uk = df[!, "3"][i]
data["gen"]["1"]["cost"][1] = value_be * 1000 #1000 multiplier for the base MVA
data["gen"]["2"]["cost"][1] = value_dk * 1000 #1000 multiplier for the base MVA
data["gen"]["3"]["cost"][1] = value_uk * 1000 #1000 multiplier for the base MVA

load_be = df[!, "4"][i]
load_dk = df[!, "5"][i]
load_uk = df[!, "6"][i]
data["load"]["1"]["pd"] = load_be / 1000 #1000 devision for the base MVA
data["load"]["2"]["pd"] = load_dk / 1000
data["load"]["3"]["pd"] = load_uk / 1000
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
@show i
result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)

weight = df[!, "7"][i];
result1 = weight * result_mcdc_opf["solve_time"]
result2 = weight * result_mcdc_opf["objective"]  # Replace with actual calculation
result3 = weight * (4 - result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
result4 = weight;

# Store results in the dictionary
if !haskey(results, "result1")
    results["result1"] = []
end
if !haskey(results, "result2")
    results["result2"] = []
end
if !haskey(results, "result3")
    results["result3"] = []
end
if !haskey(results, "result4")
    results["result4"] = []
end

if result_mcdc_opf["termination_status"] == LOCALLY_SOLVED
    push!(results["result1"], result1)
    push!(results["result2"], result2)
    push!(results["result3"], result3)
    push!(results["result4"], result4)
else
    display("termination_status of iteration $i is:")
    display(result_mcdc_opf["termination_status"])
end
wind_curtail = 4 - result_mcdc_opf["solution"]["gen"]["4"]["pg"];
save_results_planning_analysis = DataFrame(c1=[], c2=[], c3=[], c4=[])
push!(save_results_planning_analysis, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_planning_analysis.csv", save_results_planning_analysis, append = true)
# end

# average_result1 = mean(results["result1"]) #solve time 
# average_result2 = mean(results["result2"]) #objective function value
# average_result3 = mean(results["result3"]) #wind curtailment in pu

average_result1 = sum(results["result1"]) / sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"]) / sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"]) / sum(results["result4"]) #wind curtailment in pu


save_results_planning_analysis = DataFrame(c1=[], c2=[], c3=[],)
push!(save_results_planning_analysis, [average_result1, average_result2, average_result3])
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_planning_analysis.csv", save_results_planning_analysis, append = true)

display(result_mcdc_opf["termination_status"])
display(result_mcdc_opf["objective"])
# display(_PM.component_table(result_mcdc_opf["solution"], "branchdc", ["i_from"]))
display(_PM.component_table(result_mcdc_opf["solution"], "gen", ["pg"]))
display(_PM.component_table(result_mcdc_opf["solution"], "convdc", ["pgrid"]))
# display(_PM.component_table(result_mcdc_opf["solution"], "busdc", ["vm"]))

# 988741.2514995509
# 987149.4042912098
# 989446.1670983923-987149.4042912098
# 989446.1670983923-988741.2514995509

# 988495.2599625002 C3
# 989747.6281482696 
# 1.0263632285127613e6

# 934669.0337660447
# 934669.0344784562 
# 990834.5651336075
# 933400.260526807
# 935546.7391313845

# 934669.0337660447- 934669.0344784562 
# 934669.0337660447- 990834.5651336075
# 934669.0337660447-  933400.260526807
# 934669.0337660447-  935546.7391313845