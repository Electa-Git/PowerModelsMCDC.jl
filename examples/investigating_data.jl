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


bus_conv_poles = Dict(
    i => Vector{Tuple{Int,String}}()
    for i in keys(data["bus"])
)
for (c,poles) in check["convdc_poles"]
    i = data["convdc"][c]["busac_i"]
    for pole in poles
        push!(bus_conv_poles["$i"], (parse(Int64,c),pole))
    end
end
#nw_ref[:bus_conv_poles] = bus_conv_poles

for (c,pole) in bus_conv_poles["7"]
    println("converter at bus 7: ", c, " pole: ", pole)
end

bus_conv_poles["7"]

check["convdc_poles"]

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


check["busdc_terminal_arcsdc"][("4","r")]


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
end


pm = solve_model_check(data, _PM.ACPPowerModel)
println(pm[:my_var])

pm