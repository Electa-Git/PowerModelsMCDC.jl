
#function comp_start_value(comp::Dict{String,<:Any}, key::String, pole::String, default)
#    return [comp_start_value(comp, key, pole, default)]
#end

function comp_start_value(comp::Dict{String,<:Any}, key::String, pole::String, default)
    if haskey(comp, key)
        return comp[key][pole]
    else
        return default
    end
end

function comp_start_value(comp::Dict{String,<:Any}, key::String, default)
    return _PM.comp_start_value(comp, key, default)
end

"""
Returns a total (shunt+series) power magnitude bound for the from and to side
of a branch. The total current rating also implies a current bound through the
upper bound on the voltage magnitude of the connected buses.
"""
function _calc_branch_power_max_frto(branch::Dict, bus_fr::Dict, bus_to::Dict)
    return _calc_branch_power_max(branch, bus_fr), _calc_branch_power_max(branch, bus_to)
end


## Updated variables
function variable_mc_dcbranch_current(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:i_dcgrid] = Dict(((l, i, j)) => JuMP.@variable(pm.model,
    [cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"])], base_name = "$(nw)_idcgrid_$((l,i,j))",
    start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "i_start", cond, 0.0)
    ) for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
    )
    
    for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
        for cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"]) 
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j)][cond], -(_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                    JuMP.set_upper_bound.(vars[(l, i, j)][cond],  (_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                end
            end
        end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report && sol_component_value_edge_status(pm, nw, :branchdc, :i_from, :i_to, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end

# This has to be fixed
function variable_mc_dcbranch_current_mc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:i_dcgrid] = Dict(((l, i, j)) => JuMP.@variable(pm.model,
    [cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"])], base_name = "$(nw)_idcgrid_$((l,i,j))",
    start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "i_start", cond, 0.0)
    ) for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
    )
    
    for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
        for cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"]) 
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j)][cond], -(_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                    JuMP.set_upper_bound.(vars[(l, i, j)][cond],  (_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                end
            end
        end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report #&& sol_component_value_edge_status_sw(pm, nw, :branchdc, :i_from, :i_to, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end

function variable_mc_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:p_dcgrid] = Dict(((l, i, j)) => JuMP.@variable(pm.model,
       [cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"])], base_name = "$(nw)_pdcgrid_$((l,i,j))",
       start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", cond, 0.0)
    ) for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
    )
    
    
    for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
        for cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"]) 
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j)][cond], -_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])
                    JuMP.set_upper_bound.(vars[(l, i, j)][cond], _PM.ref(pm, nw, :branchdc, l)["rateA"][cond])
                end
            end
        end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report && sol_component_value_edge_status(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end

# This has to be fixed
function variable_mc_active_dcbranch_flow_mc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:p_dcgrid] = Dict(((l, i, j)) => JuMP.@variable(pm.model,
       [cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"])], base_name = "$(nw)_pdcgrid_$((l,i,j))",
       start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", cond, 0.0)
    ) for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
    )
    
    
    for (l, i, j) in _PM.ref(pm, nw, :arcsdc)
        for cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"]) 
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j)][cond], -_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])
                    JuMP.set_upper_bound.(vars[(l, i, j)][cond], _PM.ref(pm, nw, :branchdc, l)["rateA"][cond])
                end
            end
        end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report #&& sol_component_value_edge_status_sw(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end


function variable_mcdcgrid_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    
    vars = _PM.var(pm, nw)[:vdcm] = Dict(i => JuMP.@variable(pm.model,
    [terminal in keys(_PM.ref(pm, nw, :busdc)[i]["Vdc"])],base_name = "$(nw)_vdcm_$(i)",
    start = comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", terminal, 1.0)
    ) for i in _PM.ids(pm, nw, :busdc) 
    )


    for i in _PM.ids(pm, nw, :busdc)
        for terminal in keys(_PM.ref(pm, nw, :busdc)[i]["Vdc"])
            if bounded
                JuMP.set_lower_bound.(vars[i][terminal], _PM.ref(pm, nw, :busdc, i)["Vdcmin"][terminal])
                JuMP.set_upper_bound.(vars[i][terminal], _PM.ref(pm, nw, :busdc, i)["Vdcmax"][terminal])
            end
        end
    end

    terminals = Dict(
        i => collect(keys(_PM.ref(pm, nw, :busdc)[i]["Vdc"]))
        for i in _PM.ids(pm, nw, :busdc)
    )

    report && sol_component_value_status(pm, nw, :busdc, :vm, _PM.ids(pm, nw, :busdc), terminals, vars)
end
