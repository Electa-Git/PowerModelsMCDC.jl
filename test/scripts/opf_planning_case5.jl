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

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 1,  "print_user_options"=>"yes")

# file = "./test/data/planning/demogrid_case_1_bipolar.m"
# file = "./test/data/planning/demogrid_case_2_sym_monopolar_2GW.m"
# file = "./test/data/planning/demogrid_case_3_Asym_monopolar_2GW.m"
# file = "./test/data/planning/demogrid_case_4_sym_monopolar_1GW.m"
file = "./test/data/planning/demogrid_case_5_sym_monopolar_1GW_320.m"

# ###################### import day-ahaed price and load data ==> base case #################
#  empty!(data)
 data = PowerModelsMCDC.parse_file(file);
 using Statistics  # For calculating the mean

results = Dict{String, Vector{Float64}}()

# Specify the path to your CSV file
# file_path = "./test/data/planning/Day-ahead Prices_2023_UK.csv"
# file_path = "./test/data/planning/Day-ahead Prices_2023_BE.csv"
# file_path = "./test/data/planning/gen_and_load/Day-ahead Prices_2020BE.csv"

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data
# length( df[!,"1"])
for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> Conv-1 out case case #################
empty!(data)
 data = PowerModelsMCDC.parse_file(file);
 data["convdc"]["1"]["status"]=0
#  data["convdc"]["5"]["status"]=0
 data["convdc"]["4"]["ground_type"]=1
 
results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)


###################### import day-ahaed price and load data ==> Conv-2 out case case #################
empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["convdc"]["2"]["status"]=0
# data["convdc"]["6"]["status"]=0

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> Conv-3 out case case #################
empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["convdc"]["3"]["status"]=0
# data["convdc"]["7"]["status"]=0

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> Conv-4 out case case #################
empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["convdc"]["4"]["status"]=0
# data["convdc"]["8"]["status"]=0

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> branchdc-1 out case case #################
empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["branchdc"]["1"]["status"] = 0;
# data["branchdc"]["1"]["line_confi"] = 1;
# data["branchdc"]["1"]["connect_at"] = 2 ;
# data["branchdc"]["1"]["rateA"] = 1000
# data["branchdc"]["1"]["rateB"] = 1000
# data["branchdc"]["1"]["rateC"] = 1000


results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> branchdc-2 out case case #################
empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["branchdc"]["2"]["status"] = 0;
# data["branchdc"]["2"]["line_confi"] = 1;
# data["branchdc"]["2"]["connect_at"] = 2 ;
# data["branchdc"]["2"]["rateA"] = 1000
# data["branchdc"]["2"]["rateB"] = 1000
# data["branchdc"]["2"]["rateC"] = 1000

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> branchdc-3 out case case #################

empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["branchdc"]["3"]["status"] = 0;
# data["branchdc"]["3"]["line_confi"] = 1;
# data["branchdc"]["3"]["connect_at"] = 2 ;
# data["branchdc"]["3"]["rateA"] = 1000
# data["branchdc"]["3"]["rateB"] = 1000
# data["branchdc"]["3"]["rateC"] = 1000

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> branchdc-4 out case case #################

empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["branchdc"]["4"]["status"] = 0;
# data["branchdc"]["4"]["line_confi"] = 1;
# data["branchdc"]["4"]["connect_at"] = 2 ;
# data["branchdc"]["4"]["rateA"] = 1000
# data["branchdc"]["4"]["rateB"] = 1000
# data["branchdc"]["4"]["rateC"] = 1000
results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)

###################### import day-ahaed price and load data ==> branchdc-5 out case case #################

empty!(data)
data = PowerModelsMCDC.parse_file(file);
data["branchdc"]["5"]["status"] = 0;
# data["branchdc"]["5"]["line_confi"] = 1;
# data["branchdc"]["5"]["connect_at"] = 2 ;
# data["branchdc"]["5"]["rateA"] = 1000
# data["branchdc"]["5"]["rateB"] = 1000
# data["branchdc"]["5"]["rateC"] = 1000

results = Dict{String, Vector{Float64}}()

file_path = "./test/data/planning/gen_and_load/clean_load_gen2020_kmean_120.csv"
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data

for i in 1:length( df[!,"1"])
    # for i in 200:250
    # i=1
    value_be = df[!,"1"][i]
    value_dk = df[!,"2"][i]
    value_uk = df[!,"3"][i]
    data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
    data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
    data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
    load_be = df[!,"4"][i]
    load_dk = df[!,"5"][i]
    load_uk = df[!,"6"][i]
    data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
    data["load"]["2"]["pd"] = load_dk/1000
    data["load"]["3"]["pd"] = load_uk/1000
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
    @show i 
    result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)
    
    weight= df[!,"7"][i];
    result1 = weight*result_mcdc_opf["solve_time"]
    result2 = weight*result_mcdc_opf["objective"]  # Replace with actual calculation
    result3 = weight*(4-result_mcdc_opf["solution"]["gen"]["4"]["pg"]) # Replace with actual calculation
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
    wind_curtail= 4-result_mcdc_opf["solution"]["gen"]["4"]["pg"];
    save_results_detailed_case5 = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [])
    push!(save_results_detailed_case5, [result_mcdc_opf["termination_status"], result_mcdc_opf["objective"], wind_curtail, weight])
    CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_detailed_case5.csv", save_results_detailed_case5, append = true)
end

average_result1 = sum(results["result1"])/sum(results["result4"]) #solve time 
average_result2 = sum(results["result2"])/sum(results["result4"]) #objective function value
average_result3 = sum(results["result3"])/sum(results["result4"]) #wind curtailment in pu


save_results_summary_case5 = DataFrame( c1 = [], c2 = [], c3 = [], )
push!(save_results_summary_case5, [average_result1, average_result2, average_result3])
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF Francesco/Simulations June 2024/planning related OPF/with 120 wighted samples/save_results_summary_case5.csv", save_results_summary_case5, append = true)


# ########################## with kmeans data ###########
# data = PowerModelsMCDC.parse_file(file);
# data["convdc"]["4"]["status"]=0
# # Specify the path to your CSV file
# # file_path = "./test/data/planning/Day-ahead Prices_2023_UK.csv"
# # file_path = "./test/data/planning/Day-ahead Prices_2023_BE.csv"
# file_path = "./test/data/planning/gen_and_load/Day-ahead Prices_2020BE_kmean.csv"

# # Read the CSV file into a DataFrame
# # df_km = DataFrame( c1 = [])
# # push!(df_km, ["kmean prices"])
# # df_km2 = CSV.read(file_path, DataFrame);
# # push!(df_km, CSV.read(file_path, DataFrame))
# df_km=CSV.read(file_path, DataFrame)

# # length(df[!, "Day-ahead Price [EUR/MWh]"])
# for i in 1:length(df_km[!,"0"])
#     value_be = df_km[!,"0"][i]
#     data["gen"]["1"]["cost"][1]= value_be*1000 #1000 multiplier for the base MVA
#     # data["gen"]["2"]["cost"][1]= value_dk*1000 #1000 multiplier for the base MVA
#     # data["gen"]["3"]["cost"][1]= value_uk*1000 #1000 multiplier for the base MVA
    
#     # data["load"]["1"]["pd"] = load_be/1000 #1000 devision for the base MVA
#     # data["load"]["2"]["pd"] = load_dk/1000
#     # data["load"]["3"]["pd"] = load_uk/1000

#     s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
#     @show i 
#     result_mcdc_opf = PowerModelsMCDC.solve_mcdcopf(data, _PM.ACPPowerModel, ipopt_solver, setting=s)

#   print(result_mcdc_opf["objective"])
# #   @info pwd()
#  # include("test/scripts/write_to_csv_planning.jl")
#   include("/Users/cjat/.julia/dev/PowerModelsMCDC/test/scripts/write_to_csv_planning.jl")
    
# end

# # data["convdc"]["1"]["status"]=0
# # data["convdc"]["2"]["status"]=0
# # # data["convdc"]["5"]["status"]=0
# # data["convdc"]["6"]["status"]=0


# _PM.component_table(result_mcdc_opf["solution"], "bus", ["va"])
#  _PM.component_table(result_mcdc_opf["solution"], "bus", ["vm"])
#  _PM.component_table(result_mcdc_opf["solution"], "busdc", ["vm"])
#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pgrid"])
#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["pdc"])
#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["iconv"])
#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["iconv_dc"])
 
#  _PM.component_table(result_mcdc_opf["solution"], "branchdc", ["i_from"])

#  _PM.component_table(result_mcdc_opf["solution"], "convdc", ["qgrid"])
#  _PM.component_table(result_mcdc_opf["solution"], "gen", ["pg"])

 # result_mcdc_opf = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt_solver, setting=s)
#  print(result_mcdc_opf["objective"])
#  #   @info pwd()
#    print(_PM.component_table(result_mcdc_opf["solution"], "gen", ["pg"]))
