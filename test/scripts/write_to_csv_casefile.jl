using CSV
using DataFrames

file = "./test/data/matacdc_scripts_pf/Three_terminal_mcdc_pf.m"
data = PowerModelsMCDC.parse_file(file)
result = result_mcdc_opf

bus_data = DataFrame(c1=[], c2=[], c3=[], c4=[], c5=[], c6=[])
push!(bus_data, ["Conv no", "Pc=pgrid", "Qc=qgrid", "Pdc", "Pdcg"])
# #for (n,nw) in result["solution"]
for (i, conv) in data["convdc"]
    Pc= conv["pg"]
    Qc= conv["qg"]
    pdc = result["solution"]["convdc"]["$i"]["pdc"]
    pdcg = result["solution"]["convdc"]["$i"]["pdcg"]
    push!(conv_sp, ["$i", Pc, Qc, pdc, pdcg])
end

branch_data =

busdc_data =

branchdc_data =

conv_data = DataFrame(c1=[], c2=[], c3=[], c4=[], c5=[], c6=[])
push!(conv_data, ["Conv no", "Pc=pgrid", "Qc=qgrid", "Pdc", "Pdcg"])
# #for (n,nw) in result["solution"]
for (i, conv) in data["convdc"]
    Pc= conv["pg"]
    Qc= conv["qg"]
    pdc = result["solution"]["convdc"]["$i"]["pdc"]
    pdcg = result["solution"]["convdc"]["$i"]["pdcg"]
    push!(conv_sp, ["$i", Pc, Qc, pdc, pdcg])
end
# end


# for writing the dataframes to csv files
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/Nov28/conv_settings.csv", conv_sp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/Nov28/brAC.csv", brsp, append=true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/Nov28/brdcAC.csv", brdcsp, append=true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/Nov28/comp_details.csv", comp_details, append=true)
