constraint_voltage_dc(pm::_PM.AbstractPowerModel) = constraint_voltage_dc(pm, _PM.nw_id_default)
# no data, so no further templating is needed, constraint goes directly to the formulations

function constraint_kcl_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_conv_poles = _PM.ref(pm, nw, :bus_conv_poles, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_conv_poles, bus_loads, bus_shunts, pd, qd, gs, bs)
end


function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    busdc = _PM.ref(pm, nw, :busdc, i)
    busdc_terminal_arcsdc = _PM.ref(pm, nw, :busdc_terminal_arcsdc)
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)
    busdc_grounded_convs = _PM.ref(pm, nw, :busdc_grounded_convs)

    constraint_kcl_shunt_dcgrid(pm, nw, i, busdc["Pdc"], busdc["terminals"], busdc_terminal_arcsdc, busdc_terminal_conv_poles, busdc_grounded_convs)
end

function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    total_cond = _PM.ref(pm, nw, :branchdc, i, "conductors")
    p = _PM.ref(pm, nw, :dcpol)
    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p, total_cond)
end

function constraint_converter_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        plmax = conv["LossA"][cond] + conv["LossB"][cond] * conv["Pacrated"][cond] + conv["LossCinv"][cond] * (conv["Pacrated"][cond])^2
        constraint_converter_losses(pm, nw, i, a[cond], b[cond], c[cond], plmax, cond)
    end
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    busdc_grounded_convs = _PM.ref(pm, nw, :busdc_grounded_convs)
    r_earth = 0.0

    constraint_converter_dc_ground_shunt_ohm(pm, nw, busdc_grounded_convs, r_earth)
end

function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        Vmax = conv["Vmmax"][cond]
        Imax = conv["Imax"][cond]
        constraint_converter_current(pm, nw, i, Vmax, Imax, cond)
    end
end

function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    busdc_terminal_conv_poles = _PM.ref(pm, n, :busdc_terminal_conv_poles)

    constraint_dc_voltage_magnitude_setpoint(pm, nw, i, conv["busdc_i"], conv["Vdcset"], busdc_terminal_conv_poles)
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    busdc = _PM.ref(pm, nw, :busdc, conv["busdc_i"])
    busdc_terminal_conv_poles = _PM.ref(pm, nw, :busdc_terminal_conv_poles)

    bus_cond_convs_dc_cond = Dict(c => busdc_terminal_conv_poles[(conv["busdc_i"], c)] for c in 1:busdc["terminals"])
    #vdcm = [c == 3 ? -0.0 : sign(busdc["Vdcmin"][c]) for c in 1:busdc["terminals"]]

    constraint_converter_dc_current(pm, nw, i, conv["busdc_i"], vdcm, bus_cond_convs_dc_cond)
end

function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        constraint_active_conv_setpoint(pm, nw, i, conv["P_g"][cond], cond)
    end
end

function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        constraint_reactive_conv_setpoint(pm, nw, i, conv["Q_g"][cond], cond)
    end
end

function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        constraint_conv_reactor(pm, nw, i, conv["rc"][cond], conv["xc"][cond], Bool(conv["reactor"]), cond)
    end
end

function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        constraint_conv_filter(pm, nw, i, conv["bf"][cond], Bool(conv["filter"]), cond)
    end
end

function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        constraint_conv_transformer(pm, nw, i, conv["rtf"][cond], conv["xtf"][cond], conv["busac_i"], conv["tm"][cond], Bool(conv["transformer"]), cond)
    end
end

function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :conv_acpoles, i))
    for cond in active_pole
        S = conv["Pacrated"][cond]
        P1 = cos(0) * S
        Q1 = sin(0) * S
        P2 = cos(pi) * S
        Q2 = sin(pi) * S
        constraint_conv_firing_angle(pm, nw, i, S, P1, Q1, P2, Q2, cond)
    end
end

### New constraints
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

    constraint_kcl_shunt_dcgrid_new(pm, nw, i, busdc_terminal_arcsdc_, busdc_terminal_conv_poles_, busdc_grounded_convs_)
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
    println("busdc: ", busdc)
    terminals = keys(_PM.ref(pm, nw, :busdc_terminal_conv_poles,busdc)) #terminal
    println("terminals: ", terminals)
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
