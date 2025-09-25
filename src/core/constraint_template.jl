### Updated constraints
function constraint_kcl_shunt_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
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

    constraint_kcl_shunt_new(pm, nw, i, bus_arcs, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_dcgrid_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    busdc = _PM.ref(pm, nw, :busdc, i)
    busdc_terminal_arcsdc_ = _PM.ref(pm, nw, :busdc_terminal_arcsdc)
    busdc_terminal_conv_poles_ = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    busdc_grounded_convs_ = _PM.ref(pm, nw, :busdc_grounded_convs)
    bus_convs_i_dc_cond_ = _PM.ref(pm, nw, :busdc_terminal_i_conv_dc_poles)
    constraint_kcl_shunt_dcgrid_new(pm, nw, i, busdc_terminal_arcsdc_, busdc_terminal_conv_poles_, busdc_grounded_convs_, bus_convs_i_dc_cond_)
end

function constraint_ohms_dc_branch_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    constraint_ohms_dc_branch_new(pm, nw, f_bus, t_bus, f_idx, t_idx, branch)
end


function constraint_converter_losses_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        println("Converter: $i, Pole: $pole")
    #plmax = conv["LossA"][cond] + conv["LossB"][cond] * conv["Pacrated"][cond] + conv["LossCinv"][cond] * (conv["Pacrated"][cond])^2
        constraint_converter_losses_new(pm, nw, i, conv, pole)
    end
end


function constraint_converter_current_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    
    for pole in poles
        constraint_converter_current_new(pm, nw, i, pole)
    end
end

function constraint_converter_dc_current_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    busdc = conv["busdc_i"]
    terminals = keys(_PM.ref(pm, nw, :busdc_terminal_conv_poles,busdc)) #terminal
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    constraint_converter_dc_current_new(pm, nw, i, busdc, terminals, poles, busdc_terminal_conv_poles)
end

function constraint_conv_transformer_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_transformer_new(pm, nw, i, conv["rtf"][pole], conv["xtf"][pole], conv["busac_i"], conv["tm"][pole], Bool(conv["transformer"]), pole)
    end
end

function constraint_conv_reactor_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_reactor_new(pm, nw, i, conv["rc"][pole], conv["xc"][pole], Bool(conv["reactor"]), pole)
    end
end

function constraint_conv_filter_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_filter_new(pm, nw, i, conv["bf"][pole], Bool(conv["filter"]), pole)
    end
end

function constraint_conv_firing_angle_new(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    poles = keys(conv["status"])
    for pole in poles
        constraint_conv_firing_angle_new(pm, nw, i, pole)
    end
end

function constraint_converter_dc_ground_shunt_ohm_new(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    busdc_grounded_convs = _PM.ref(pm, nw, :busdc_grounded_convs)
    r_earth = 0.0

    constraint_converter_dc_ground_shunt_ohm_new(pm, nw, busdc_grounded_convs, r_earth)
end
