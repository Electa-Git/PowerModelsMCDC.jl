# OPF problem, nonlinear formulation

import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt

nlp_solver = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
file = "$(dirname(@__DIR__))/test/data/case5_2grids_MC.m"


data = _PMMCDC.parse_file(file)

s = Dict("conv_losses_mp" => false)
#result_mcdc = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, nlp_solver, setting=s)


## Comparison with PowerModelsACDC (single conductor model)
#=
import PowerModelsACDC as _PMACDC

result_acdc = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, nlp_solver, setting=s)

printstyled("Multiconductor OPF\n"; bold=true)
println(" termination status: ", result_mcdc["termination_status"])
println("          objective: ", result_mcdc["objective"])
println("         solve time: ", result_mcdc["solve_time"])

printstyled("\nSingle-conductor OPF\n"; bold=true)
println(" termination status: ", result_acdc["termination_status"])
println("          objective: ", result_acdc["objective"])
println("         solve time: ", result_acdc["solve_time"])
=#




########################
# Playing around

check = Dict{String,Any}()
check["busdc"] = Dict{Int,Any}()
check["branchdc"] = Dict{Int,Any}()
check["convdc"] = Dict{Int,Any}()

# Filter DC branches that are connected to nonexistent buses
check["branchdc"] = Dict(b => branch for (b,branch) in data["branchdc"])

# Filter converters that are connected to nonexistent buses
check["convdc"] = Dict(c => conv for (c,conv) in data["convdc"])

# DC arcs: tuples of the form (l,i,j) where l is the DC branch and i and j are the adjacent DC buses
check["arcsdc_from"] = [(b, branch["fbusdc"], branch["tbusdc"]) for (b, branch) in data["branchdc"]]
check["arcsdc_to"]   = [(b, branch["tbusdc"], branch["fbusdc"]) for (b, branch) in data["branchdc"]]
check["arcsdc"]      = [check["arcsdc_from"]; check["arcsdc_to"]]

check["busdc_terminals"] = Dict(
    i => Set(("p", "r", "n"))
    for i in keys(data["busdc"])
)

check["branchdc_conductors"] = Dict(
    b => Set(conductor for (conductor, status) in branch["status"] if status == 1)
    for (b, branch) in data["branchdc"]
)

check["convdc_poles"] = Dict(
    c => Set(pole for (pole, status) in conv["status"] if status == 1)
    for (c, conv) in data["convdc"]
)

check["branchdc_conductors"]["1"]


# CHANGED STRUCTURE OF THIS ONE
bus_conv_poles = Dict(
    i => Dict()
    for i in keys(data["bus"])
)

for (c,poles) in check["convdc_poles"]
    i = data["convdc"][c]["busac_i"]
    bus_conv_poles["$i"] = Dict(c => Vector{String}())
    #bus_conv_poles["$i"]["$c"] => Vector{String}()
    for pole in poles
        push!(bus_conv_poles["$i"]["$c"],pole)
    end
end
check["bus_conv_poles"] = bus_conv_poles
#nw_ref[:bus_conv_poles] = bus_conv_poles

for (c,pole) in bus_conv_poles["7"]
    println("converter at bus 7: ", c, " pole: ", pole)
end

bus_conv_poles["7"]["2"]

check["convdc_poles"]["2"]

busdc_terminal_arcsdc = Dict(
    (i,t) => Vector{Tuple{String,Int,Int}}()
    for (i,terminals) in check["busdc_terminals"]
    for t in terminals
)
for (l,i,j) in check["arcsdc"]
    for conductor in check["branchdc_conductors"][l]
        terminal = conductor
        println("arc: ", (l,i,j), " conductor: ", conductor)
        push!(busdc_terminal_arcsdc["$i",terminal], (l,i,j))
    end
end
check["busdc_terminal_arcsdc"] = busdc_terminal_arcsdc


# Map DC bus to connected grounded converters
busdc_grounded_convs = Dict(
    i => Vector{Int}()
    for i in keys(data["busdc"])
)
for (c,conv) in data["convdc"]
    if conv["ground_type"] == 1
        push!(busdc_grounded_convs["$(conv["busdc_i"])"], parse(Int64,c))
    end
end
check["busdc_grounded_convs"] = busdc_grounded_convs

isempty(check["busdc_grounded_convs"]["4"])


busdc_terminal_conv_poles_old = Dict((parse(Int64,i),t) => Vector{Tuple{Int,String}}()
    for (i,terminals) in check["busdc_terminals"] for t in terminals
)
for (c,poles) in check["convdc_poles"]
    i = data["convdc"][c]["busdc_i"]
    if "p" in poles
        push!(busdc_terminal_conv_poles_old[i,"p"], (parse(Int64,c),"p"))
        push!(busdc_terminal_conv_poles_old[i,"r"], (parse(Int64,c),"p"))
    end
    if "r" in poles
        push!(busdc_terminal_conv_poles_old[i,"p"], (parse(Int64,c),"r"))
        push!(busdc_terminal_conv_poles_old[i,"n"], (parse(Int64,c),"r"))
    end
    if "n" in poles
        push!(busdc_terminal_conv_poles_old[i,"r"], (parse(Int64,c),"n"))
        push!(busdc_terminal_conv_poles_old[i,"n"], (parse(Int64,c),"n"))
    end
end
check["busdc_terminal_conv_poles_old"] = busdc_terminal_conv_poles_old


for br in busdc_terminal_arcsdc["4","p"]
    println(br)
end

busdc_terminal_conv_poles = Dict(
    # i are buses amnd they can have up to three TERMINALS p,r,n
    b_id => Dict()
    for b_id in keys(data["busdc"])
)
for b_id in keys(busdc_terminal_conv_poles)
    for terminal in keys(data["busdc"][b_id]["Vdc"])
        busdc_terminal_conv_poles["$b_id"][terminal] = Vector{Tuple{Int,String}}()
    end
end
for (c,poles) in check["convdc_poles"]
    b_id = data["convdc"][c]["busdc_i"]
    if "p" in poles
        push!(busdc_terminal_conv_poles["$b_id"]["p"],(parse(Int64,c),"p"))
        push!(busdc_terminal_conv_poles["$b_id"]["r"],(parse(Int64,c),"p"))
    end
    if "r" in poles
        push!(busdc_terminal_conv_poles["$b_id"]["p"],(parse(Int64,c),"r"))
        push!(busdc_terminal_conv_poles["$b_id"]["n"],(parse(Int64,c),"r"))
    end
    if "n" in poles
        push!(busdc_terminal_conv_poles["$b_id"]["r"],(parse(Int64,c),"n"))
        push!(busdc_terminal_conv_poles["$b_id"]["n"],(parse(Int64,c),"n"))
    end
end

busdc_terminal_conv_poles["1"]

## UPDATE THE BASE FUNCTION AND BRACE YOURSELF FOR THE NEXT ONEÍ


function solve_mcdcopf_new(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_model_check; ref_extensions=[_PMMCDC.add_ref_dcgrid!], kwargs...)
end


function solve_model_check(data::Dict{String,Any}, model_type::Type; kwargs...)
    return _PM.instantiate_model(data, model_type, build_model_check; ref_extensions=[_PMMCDC.add_ref_dcgrid!], kwargs...)
end

"""
    build_mcdcopf(pm::PowerModels.AbstractPowerModel)

Build the OPF problem over a hybrid AC/DC network, using a multi-conductor model for the DC part.

The objective is the minimization of generation cost.
"""
function build_model_check(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded=true)
    _PM.variable_gen_power(pm, bounded=true)
    _PM.variable_branch_power(pm, bounded=true)

    _PMMCDC.variable_mc_active_dcbranch_flow_new(pm, bounded=true)
    _PMMCDC.variable_mc_dcbranch_current_new(pm, bounded=true)
    _PMMCDC.variable_mcdcgrid_voltage_magnitude_new(pm, bounded=true)
    _PMMCDC.variable_mcdc_converter_new(pm, bounded=true)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_voltage(pm)
    _PMMCDC.constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end
    
    for i in _PM.ids(pm, :bus)
        _PMMCDC.constraint_kcl_shunt_new(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        _PMMCDC.constraint_kcl_shunt_dcgrid_new(pm, i)
    end

    for i in _PM.ids(pm, :branchdc)
        _PMMCDC.constraint_ohms_dc_branch_new(pm, i)
    end

    for i in _PM.ids(pm, :convdc)
        _PMMCDC.constraint_converter_losses_new(pm, i)
        _PMMCDC.constraint_converter_current_new(pm, i)
        _PMMCDC.constraint_converter_dc_current_new(pm, i)
        _PMMCDC.constraint_conv_transformer_new(pm, i)
        _PMMCDC.constraint_conv_reactor_new(pm, i)
        _PMMCDC.constraint_conv_filter_new(pm, i)

        if pm.ref[:it][_PM.pm_it_sym][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            _PMMCDC.constraint_conv_firing_angle(pm, i)
        end
    end
    _PMMCDC.constraint_converter_dc_ground_shunt_ohm_new(pm)
end


pm = solve_model_check(data, _PM.ACPPowerModel)
result = solve_mcdcopf_new(data, _PM.ACPPowerModel, nlp_solver, setting=s)



pm.ref[:it][:pm][:nw][0][:arcsdc]
pm.var[:it][:pm][:nw][0][:pconv_tf_fr][3]
pm.var[:it][:pm][:nw][0][:i_dcgrid][(2,4,2)]
first(axes(pm.var[:it][:pm][:nw][0][:iconv_dcg][1]))

pm.ref[:it][:pm][:nw][0][:bus_conv_poles]
pm.ref[:it][:pm][:nw][0][:busdc_grounded_convs]
pm.ref[:it][:pm][:nw][0][:busdc_terminal_conv_poles]

pm.ref[:it][:pm][:nw][0][:busdc_terminal_arcsdc]
pm.ref[:it][:pm][:nw][0][:busdc_terminal_conv_poles][1]
pm.ref[:it][:pm][:nw][0][:busdc_grounded_convs]


busdc_terminal_conv_poles["1"]

#pm.var[:it][:pm][:nw][0][:vmc][1][4]["n"]
#pm.var[:it][:pm][:nw][0][:vaf_check][3]




#convs_ac_cond = Dict(i => conv["status"] for (i, conv) in data["convdc"]) 
#convs_ac_cond["1"]

for (cv_id,cv) in data["convdc"]
    cv["transformer"] = 0
    cv["reactor"]= 0
    cv["filter"] = 0
end

for i in keys(data["busdc"])
    println("busdc: ", i)
    #vdcm = _PM.var(pm, n, :vdcm, i)
    for cv_id in busdc_grounded_convs[i]
        println(" grounded conv: ", cv_id)
    end
end

convs_ac_cond = Dict(i => (findall(x -> !iszero(x), conv["status"]), conv["status"]) for (i, conv) in data["convdc"])