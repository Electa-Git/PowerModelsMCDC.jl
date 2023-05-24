using CSV
using DataFrames
# for saving generator and load data

# mva_base = data["1"]["baseMVA"]


# result=result_mcdc_opf

result=resultAC
# result=resultAC

conv_sp = DataFrame( c2 = [], c3 = [], c4 = [])
push!(conv_sp, ["Conv no","Pc","Qc"])
# #for (n,nw) in result["solution"]
	for (i, conv) in result["solution"]["convdc"]
		
		# pdc=result["solution"]["convdc"]["$i"]["pdc"]
		# pdcg=result["solution"]["convdc"]["$i"]["pdcg"]
	push!(conv_sp, [ "$i", result["solution"]["convdc"]["$i"]["pgrid"], result["solution"]["convdc"]["$i"]["qgrid"] ])
end

# end

# conv_settings = DataFrame( c1 = [], c2 = [], c3 = [], c4 = [], c5 = [], c6 = [],c7 = [], c8 = [])
# push!(conv_settings, ["Case","number","P_setpoint","Q_setpoint", "pmax", "pmin", "qmax", "qmin"])

# 	for (i, conv) in result["solution"]["convdc"]
# 		push!(conv_settings, ["BC","$i", (opf_bc["solution"]["convdc"]["$i"]["pgrid"]), (result["solution"]["convdc"]["$i"]["qgrid"]), (datadc_new["1"]["convdc"]["$i"]["Pacmax"]), (data["1"]["convdc"]["$i"]["Pacmin"]), (data["1"]["convdc"]["$i"]["Qacmax"]), (data["1"]["convdc"]["$i"]["Qacmin"])])
# 	end

gen_sp = DataFrame( c2 = [], c3 = [], c4 = [])
push!(gen_sp, ["Gen no","PG","QG"])
#for (n,nw) in result["solution"]
	for (i, gen) in result["solution"]["gen"]
	push!(gen_sp, ["$i", result["solution"]["gen"]["$i"]["pg"],  result["solution"]["gen"]["$i"]["qg"]])
end
# end


volt = DataFrame( c2 = [], c3 = [])
push!(volt, ["Bus no","Vm"])
#for (n,nw) in result["solution"]
	for (i, bus) in result["solution"]["bus"]
	push!(volt, ["$i", result["solution"]["bus"]["$i"]["vm"]])
end
# end

voltdc = DataFrame( c2 = [], c3 = [])
push!(voltdc, ["Bus no","Vm"])
#for (n,nw) in result["solution"]
	for (i, busdc) in result["solution"]["busdc"]
	push!(voltdc, ["$i", result["solution"]["busdc"]["$i"]["vm"]])
end
# end

# loadsp = DataFrame( c2 = [], c3 = [], c4 = [], c5 = [], c6 = [])
# push!(loadsp, ["Load no","Pl","Ql","Pdelta","Qdelta"])
# #for (n,nw) in result["solution"]
# 	for (i, load) in result["solution"]["load"]
# 	push!(loadsp, ["$i",datadc_new["load"]["$i"]["pl"],  result["solution"]["load"]["$i"]["ql"],  result["solution"]["load"]["$i"]["pl_delta"],  result["solution"]["load"]["$i"]["ql_delta"]])
# end
# end

brsp = DataFrame( c2 = [], c3 = [], c4 = [], c5 = [], c6 = [])
push!(brsp, ["Branch no","Pf","Qf","Pt","Qt"])
#for (n,nw) in result["solution"]
	for (i, branch) in result["solution"]["branch"]
	push!(brsp, ["$i", result["solution"]["branch"]["$i"]["pf"],  result["solution"]["branch"]["$i"]["qf"],  result["solution"]["branch"]["$i"]["pt"],  result["solution"]["branch"]["$i"]["qt"]])
end
# end

brdcsp = DataFrame( c2 = [], c3 = [], c4 = [])
push!(brdcsp, ["Branch no","i_from","i_to"])
#for (n,nw) in result["solution"]
	for (i, branchdc) in result["solution"]["branchdc"]
	# push!(brdcsp, ["$i", result["solution"]["branchdc"]["$i"]["i_from"],  result["solution"]["branchdc"]["$i"]["i_to"]])
	push!(brdcsp, ["$i", result["solution"]["branchdc"]["$i"]["pf"],  result["solution"]["branchdc"]["$i"]["pt"]])
end
# end


comp_details = DataFrame( c1 = [], c2 = [], c3 = [])
push!(comp_details, ["termination status","solve_time ","objective"])
# push!(comp_details, [result_mcdc["termination_status"],result_mcdc["solve_time"],result_mcdc["objective"]])
push!(comp_details, [result["termination_status"],result["solve_time"],result["objective"]])

# #for (n,nw) in result["solution"]
# 	for (i, branchdc) in result["solution"]["branchdc"]
# 	push!(brdcsp, ["$i", result["solution"]["branchdc"]["$i"]["i_from"],  result["solution"]["branchdc"]["$i"]["i_to"]])
# end
# end
# for writing the dataframes to csv files

# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecase_gen.csv", basecase_gen, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecase_conv.csv", basecase_conv, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecasev.csv", basecase_v, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecasevdc.csv", basecase_vdc, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecase_br.csv", basecase_br, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/basecase_brdc.csv", basecase_brdc, append = true)
# conv_settings
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/conv_settings.csv", conv_sp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/conv_sp.csv", conv_sp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/gen_sp.csv", gen_sp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/volt.csv", volt, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/voltdc.csv", voltdc, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/cost_total.csv", cost_total, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/cost_nw.csv", cost_nw, append = true)
# CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/loadsp.csv", loadsp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/brAC.csv", brsp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/brdcAC.csv", brdcsp, append = true)
CSV.write("/Users/cjat/OneDrive - Energyville/PM MCDC PF/simulations/April17/comp_details.csv", comp_details, append = true)