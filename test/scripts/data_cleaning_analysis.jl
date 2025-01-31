# file_path = "./test/data/planning/Day-ahead Prices_2023_BE.csv"
file_path_be = "./test/data/planning/gen_and_load/Day-ahead Prices_2020BE.csv"
file_path_dk = "./test/data/planning/gen_and_load/Day-ahead Prices_2020DK.csv"
file_path_uk = "./test/data/planning/gen_and_load/Day-ahead Prices_2020UK.csv"
 
file_path_be_load = "./test/data/planning/gen_and_load/Total Load - Day Ahead _ Actual_2020BE.csv"
file_path_dk_load = "./test/data/planning/gen_and_load/Total Load - Day Ahead _ Actual_2020DK.csv"
file_path_uk_load = "./test/data/planning/gen_and_load/Total Load - Day Ahead _ Actual_2020UK.csv"

df_be = CSV.read(file_path, DataFrame);
df_dk = CSV.read(file_path, DataFrame);
df_uk = CSV.read(file_path, DataFrame);




# Read the CSV file into a DataFrame
df = CSV.read(file_path, DataFrame);
# #update generation prices and load data
for i in 1:length(df[!, "Day-ahead Price [EUR/MWh]"])
    value = df[!, "Day-ahead Price [EUR/MWh]"][i]
    if typeof(value) == Missing 
        display("missing be price")
                @show i
                # value = df[!, "Day-ahead Price [EUR/MWh]"][i]
                # push!(df[!, "Day-ahead Price [EUR/MWh]"][i], value)
                df[!, "Day-ahead Price [EUR/MWh]"][i]= df[!, "Day-ahead Price [EUR/MWh]"][i-1]
    else
        # print(value)
    end

    value = df[!, "Day-ahead Price [EUR/MWh]"][i]
    if typeof(value) == Missing 
        display("missing be price")
                @show i
                # value = df[!, "Day-ahead Price [EUR/MWh]"][i]
                # push!(df[!, "Day-ahead Price [EUR/MWh]"][i], value)
                df[!, "Day-ahead Price [EUR/MWh]"][i]= df[!, "Day-ahead Price [EUR/MWh]"][i-1]
    else
        # print(value)
    end




end