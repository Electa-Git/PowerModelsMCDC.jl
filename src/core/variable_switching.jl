function variable_dc_switch_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, relax::Bool=false, report::Bool=true)
    if !relax
        z_dcswitch = _PM.var(pm, nw)[:z_dcswitch] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :dcswitch)], base_name="$(nw)_z_dcswitch",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :dcswitch, i), "z_dcswitch_start", 1.0)
        )
    else
        z_dcswitch = _PM.var(pm, nw)[:z_dcswitch] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :dcswitch)], base_name="$(nw)_z_dcswitch",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(ref(pm, nw, :dcswitch, i), "z_dcswitch_start", 1.0)
        )
    end

    report && _PM.sol_component_value(pm, nw, :dcswitch, :status, _PM.ids(pm, nw, :dcswitch), z_dcswitch)
end


function variable_dc_switch_power_mc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    #p_dc_sw_mc_ = _PM.var(pm, nw)[:p_dc_sw] = JuMP.@variable(pm.model,
    p_dc_sw_mc_ = _PM.var(pm, nw)[:p_dc_sw_mc] = JuMP.@variable(pm.model,
        [(l,i,j,cond) in _PM.ref(pm, nw, :arcs_from_sw_dc)], base_name="$(nw)_p_dc_sw_mc",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :dcswitch, l), "p_dc_sw_mc_start", 0.5)
    )
    
    if bounded
        flow_lb, flow_ub = _PM.ref_calc_switch_flow_bounds(_PM.ref(pm, nw, :dcswitch), _PM.ref(pm, nw, :busdc))
        for arc in _PM.ref(pm, nw, :arcs_from_sw_dc)
            l,i,j,cond = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(p_dc_sw_mc_[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(p_dc_sw_mc_[arc], flow_ub[l])
            end
        end
    end
    
    # this explicit type erasure is necessary
    p_dc_sw_mc_expr = Dict{Any,Any}((l,i,j,cond) => p_dc_sw_mc_[(l,i,j,cond)] for (l,i,j,cond) in _PM.ref(pm, nw, :arcs_from_sw_dc) )
    p_dc_sw_mc_expr = merge(p_dc_sw_mc_expr, Dict((l,j,i,cond) => -1.0*p_dc_sw_mc_[(l,i,j,cond)] for (l,i,j,cond) in _PM.ref(pm, nw, :arcs_from_sw_dc)))
    _PM.var(pm, nw)[:p_dc_sw_cond] = p_dc_sw_mc_expr
    
    #report && _PM.sol_component_value_edge(pm, nw, :dcswitch, :p_dc_sw_mc_fr, :p_dc_sw_mc_to, _PM.ref(pm, nw, :arcs_from_sw_dc), _PM.ref(pm, nw, :arcs_to_sw_dc), p_dc_sw_mc_expr)
    report #&& sol_component_value_edge_status_sw(pm, nw, :dcswitch, :p_dc_sw_mc_fr, :p_dc_sw_mc_to, _PM.ref(pm, nw, :arcs_from_sw_dc), _PM.ref(pm, nw, :arcs_to_sw_dc), p_dc_sw_mc_expr, p_dc_sw_mc_)

end

function variable_dc_switch_current_mc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    #p_dc_sw_mc_ = _PM.var(pm, nw)[:p_dc_sw] = JuMP.@variable(pm.model,
    #vars = _PM.var(pm, nw)[:i_dc_sw_mc] = Dict(((l, i, j, cond)) => JuMP.@variable(pm.model, 
    #base_name="$(nw)_i_dc_sw_mc", start = comp_start_value(_PM.ref(pm, nw, :dcswitch, l), "i_dc_sw_mc_start", 0.5))
    #for (l, i, j, cond) in _PM.ref(pm, nw, :arcs_sw_dc)
    #) 

    i_dc_sw_mc = JuMP.@variable(pm.model, [(l, i, j, cond) in _PM.ref(pm, nw, :arcs_sw_dc)],
    base_name="$(nw)_i_dc_sw_mc", start = comp_start_value(_PM.ref(pm, nw, :dcswitch, l), "i_dc_sw_mc_start", 0.5))
     

    for (l, i, j, cond) in _PM.ref(pm, nw, :arcs_sw_dc)
        if bounded
            JuMP.set_lower_bound.(i_dc_sw_mc[(l, i, j, cond)], -(_PM.ref(pm, nw, :dcswitch,l)["psw"]))
            JuMP.set_upper_bound.(i_dc_sw_mc[(l, i, j, cond)],  (_PM.ref(pm, nw, :dcswitch,l)["psw"]))
        end
    end

    isw_expr = Dict{Any,Any}((l,i,j,cond) => i_dc_sw_mc[(l,i,j,cond)] for (l,i,j,cond) in _PM.ref(pm, nw, :arcs_from_sw_dc))
    isw_expr = merge(isw_expr, Dict((l,j,i,cond) => -1.0*i_dc_sw_mc[(l,i,j,cond)] for (l,i,j,cond) in _PM.ref(pm, nw, :arcs_from_sw_dc)))
    _PM.var(pm, nw)[:i_dc_sw_mc] = isw_expr


    report && sol_component_value_edge_status_sw(pm, nw, :dcswitch, :i_sw_fr, :i_sw_to, _PM.ref(pm, nw, :arcs_from_sw_dc), _PM.ref(pm, nw, :arcs_to_sw_dc), isw_expr)
end

function variable_mc_active_dcbranch_flow_sw(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:p_dcgrid] = Dict(((l, i, j, cond)) => JuMP.@variable(pm.model, base_name = "$(nw)_pdcgrid_$((l,i,j))",
    start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", cond, 0.0)
    ) for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc)
    )
    
    for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc)
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j,cond)], -_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])
                    JuMP.set_upper_bound.(vars[(l, i, j,cond)], _PM.ref(pm, nw, :branchdc, l)["rateA"][cond])
                end
            end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report #&& sol_component_value_edge_status(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end

function variable_mc_dcbranch_current_sw(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vars = _PM.var(pm, nw)[:i_dcgrid] = Dict(((l, i, j, cond)) => JuMP.@variable(pm.model,
    [cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"])], base_name = "$(nw)_idcgrid_$((l,i,j))",
    start = comp_start_value(_PM.ref(pm, nw, :branchdc, l), "i_start", cond, 0.0)
    ) for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc)
    )
    
    for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc)
        for cond in keys(_PM.ref(pm, nw, :branchdc)[l]["status"]) 
            if _PM.ref(pm, nw, :branchdc)[l]["status"][cond] == 1
                if bounded
                    JuMP.set_lower_bound.(vars[(l, i, j, cond)][cond], -(_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                    JuMP.set_upper_bound.(vars[(l, i, j, cond)][cond],  (_PM.ref(pm, nw, :branchdc,l)["rateA"][cond])/(_PM.ref(pm, nw, :branchdc,l)["r"][cond]))
                end
            end
        end
    end

    conductors = Dict(
        l => collect(keys(_PM.ref(pm, nw, :branchdc)[l]["status"]))
        for (l, i, j, cond) in _PM.ref(pm, nw, :arcsdc_from)
    )

    report #&& sol_component_value_edge_status(pm, nw, :branchdc, :i_from, :i_to, _PM.ref(pm, nw, :arcsdc_from), _PM.ref(pm, nw, :arcsdc_to), conductors, vars)
end
