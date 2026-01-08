### Updated constraints
function constraint_kcl_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_conv_poles = _PM.ref(pm, nw, :bus_conv_poles, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt(pm, nw, i, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_sw(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_conv_poles = _PM.ref(pm, nw, :bus_conv_poles, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt_sw(pm, nw, i, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, bus_arcs_sw, pd, qd, gs, bs)
end

function constraint_kcl_shunt_fc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_conv_poles = _PM.ref(pm, nw, :bus_conv_poles, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt_fc(pm, nw, i, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    busdc = _PM.ref(pm, nw, :busdc, i)
    busdc_terminal_arcsdc_ = _PM.ref(pm, nw, :busdc_terminal_arcsdc)
    busdc_terminal_conv_poles_ = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    busdc_grounded_convs_ = _PM.ref(pm, nw, :busdc_grounded_convs)
    bus_convs_i_dc_cond_ = _PM.ref(pm, nw, :busdc_terminal_i_conv_dc_poles)
    constraint_kcl_shunt_dcgrid(pm, nw, i, busdc_terminal_arcsdc_, busdc_terminal_conv_poles_, busdc_grounded_convs_, bus_convs_i_dc_cond_)
end

function constraint_kcl_shunt_dcgrid_sw(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    busdc = _PM.ref(pm, nw, :busdc, i)
    busdc_terminal_arcsdc_ = _PM.ref(pm, nw, :busdc_terminal_arcsdc)
    busdc_terminal_conv_poles_ = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    busdc_grounded_convs_ = _PM.ref(pm, nw, :busdc_grounded_convs)
    bus_convs_i_dc_cond_ = _PM.ref(pm, nw, :busdc_terminal_i_conv_dc_poles)
    busdc_terminal_arcsdc_sw = _PM.ref(pm, nw, :busdc_terminal_arcsdc_sw)
    constraint_kcl_shunt_dcgrid_sw(pm, nw, i, busdc_terminal_arcsdc_, busdc_terminal_conv_poles_, busdc_grounded_convs_, bus_convs_i_dc_cond_,busdc_terminal_arcsdc_sw)
end


function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    println("f_bus is $f_bus")
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch)
end


function constraint_ohms_dc_branch_sw(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    println("f_bus is $f_bus")
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    constraint_ohms_dc_branch_sw(pm, nw, f_bus, t_bus, f_idx, t_idx, branch)
end

function constraint_converter_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_converter_losses(pm, nw, i, conv, pole)
    end
end


function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    println("Converter $i poles: ", poles)
    
    for pole in poles
        constraint_converter_current(pm, nw, i, pole)
    end
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    busdc = conv["busdc_i"]
    terminals = keys(_PM.ref(pm, nw, :busdc_terminal_conv_poles,busdc)) #terminal
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    constraint_converter_dc_current(pm, nw, i, busdc, terminals, poles, busdc_terminal_conv_poles)
end


function constraint_converter_dc_current_fc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    busdc = conv["busdc_i"]
    terminals = keys(conv["busdc_i"])
    terminals = keys(_PM.ref(pm, nw, :busdc_terminal_conv_poles,busdc)) #terminal
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    constraint_converter_dc_current_fc(pm, nw, i, busdc, terminals, poles, busdc_terminal_conv_poles)
end

function constraint_converter_dc_current_sw(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    busdc = conv["busdc_i"]
    terminals = keys(_PM.ref(pm, nw, :busdc_terminal_conv_poles,conv["busdc_i"][first(poles)])) #terminal
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    constraint_converter_dc_current_sw(pm, nw, i, busdc, terminals, poles, busdc_terminal_conv_poles)
end


function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_transformer(pm, nw, i, conv["rtf"][pole], conv["xtf"][pole], conv["busac_i"], conv["tm"][pole], Bool(conv["transformer"]), pole)
    end
end

function constraint_conv_transformer_sw(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_transformer_sw(pm, nw, i, conv["rtf"][pole], conv["xtf"][pole], conv["busac_i"][pole], conv["tm"][pole], Bool(conv["transformer"]), pole)
    end
end

function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_reactor(pm, nw, i, conv["rc"][pole], conv["xc"][pole], Bool(conv["reactor"]), pole)
    end
end

function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_filter(pm, nw, i, conv["bf"][pole], Bool(conv["filter"]), pole)
    end
end

function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_firing_angle(pm, nw, i, pole)
    end
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    busdc_grounded_convs = _PM.ref(pm, nw, :busdc_grounded_convs)
    r_earth = 0.0

    constraint_converter_dc_ground_shunt_ohm(pm, nw, busdc_grounded_convs, r_earth)
end

function constraint_dc_switch_voltage_on_off_big_M_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch = _PM.ref(pm, nw, :dcswitch, i)
    terminal = switch["terminal"]
    constraint_dc_switch_voltage_on_off_big_M_mc(pm, nw, i, switch["f_busdc"], switch["t_busdc"], terminal)
end

function constraint_dc_switch_thermal_limit_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch = _PM.ref(pm, nw, :dcswitch, i)

    f_idx = (i, switch["f_busdc"], switch["t_busdc"],switch["terminal"])
    constraint_dc_switch_thermal_limit_mc(pm, nw, f_idx, switch["thermal_rating"])
end

function constraint_dc_switch_current_on_off_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch = _PM.ref(pm, nw, :dcswitch, i)
    f_idx = (i, switch["f_busdc"], switch["t_busdc"], switch["terminal"])

    constraint_dc_switch_current_on_off_mc(pm, nw, i, f_idx)
end

function constraint_BS_OTS_dcbranch_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch_couple = _PM.ref(pm, nw, :dcswitch_couples, i)
    switch_ = _PM.ref(pm, nw, :dcswitch)
    branch_ = _PM.ref(pm, nw, :branchdc)
    single_switch = switch_[switch_couple["f_sw"]]
    branch_original = single_switch["original"]
    cond = single_switch["terminal"]

    constraint_BS_OTS_dcbranch_mc(pm, nw, switch_couple["f_sw"],switch_couple["t_sw"]) 
end

function constraint_exclusivity_dc_switch_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch_couple = _PM.ref(pm, nw, :dcswitch_couples, i)
    constraint_exclusivity_dc_switch_mc(pm, nw, switch_couple["f_sw"], switch_couple["t_sw"])
end

function constraint_ZIL_dc_switch_mc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    switch_couple = _PM.ref(pm, nw, :dcswitch_couples, i)
    constraint_ZIL_dc_switch_mc(pm, nw, switch_couple["f_sw"], switch_couple["dcswitch_split"])    
end