constraint_voltage_dc(pm::_PM.AbstractPowerModel) = constraint_voltage_dc(pm, _PM.nw_id_default)
# no data, so no further templating is needed, constraint goes directly to the formulations

function constraint_kcl_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = _PM.ref(pm, nw, :bus_convs_ac, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_bs(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = _PM.ref(pm, nw, :bus_convs_ac, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt_bs(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    busdc = _PM.ref(pm, nw, :busdc, i)
    bus_arcs_dcgrid_cond = _PM.ref(pm, nw, :bus_arcs_dcgrid_cond)
    bus_convs_dc_cond = _PM.ref(pm, nw, :bus_convs_dc_cond)
    bus_convs_grounding_shunt = _PM.ref(pm, nw, :bus_convs_grounding_shunt)

    constraint_kcl_shunt_dcgrid(pm, nw, i, busdc["Pdc"], busdc["conductors"], bus_arcs_dcgrid_cond, bus_convs_dc_cond, bus_convs_grounding_shunt)
end

function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    total_cond = _PM.ref(pm, nw, :branchdc, i)["conductors"]
    p = _PM.ref(pm, nw, :dcpol)
    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p, total_cond)
end

function constraint_converter_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i)) 
    for cond in active_pole
        plmax = conv["LossA"][cond] + conv["LossB"][cond] * conv["Pacrated"][cond] + conv["LossCinv"][cond] * (conv["Pacrated"][cond])^2
        constraint_converter_losses(pm, nw, i, a[cond], b[cond], c[cond], plmax, cond)
    end
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    bus_convs_grounding_shunt = _PM.ref(pm, nw, :bus_convs_grounding_shunt)
    r_earth = 0.0

    constraint_converter_dc_ground_shunt_ohm(pm, nw, bus_convs_grounding_shunt, r_earth)
end

function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        Vmax = conv["Vmmax"][cond]
        Imax = conv["Imax"][cond]
        constraint_converter_current(pm, nw, i, Vmax, Imax, cond)
    end
end

function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    bus_convs_dc_cond = _PM.ref(pm, n, :bus_convs_dc_cond)

    constraint_dc_voltage_magnitude_setpoint(pm, nw, i, conv["busdc_i"], conv["Vdcset"], bus_convs_dc_cond)
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    busdc = _PM.ref(pm, nw, :busdc, conv["busdc_i"])
    bus_convs_dc_cond = _PM.ref(pm, nw, :bus_convs_dc_cond)

    bus_cond_convs_dc_cond = Dict(c => bus_convs_dc_cond[(conv["busdc_i"], c)] for c in 1:busdc["conductors"])
    vdcm = [c == 3 ? -0.0 : sign(busdc["Vdcmin"][c]) for c in 1:busdc["conductors"]]

    constraint_converter_dc_current(pm, nw, i, conv["busdc_i"], vdcm, bus_cond_convs_dc_cond)
end

function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        constraint_active_conv_setpoint(pm, nw, i, conv["P_g"][cond], cond)
    end
end

function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        constraint_reactive_conv_setpoint(pm, nw, i, conv["Q_g"][cond], cond)
    end
end

function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        constraint_conv_reactor(pm, nw, i, conv["rc"][cond], conv["xc"][cond], Bool(conv["reactor"]), cond)
    end
end

function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        constraint_conv_filter(pm, nw, i, conv["bf"][cond], Bool(conv["filter"]), cond)
    end
end

function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        constraint_conv_transformer(pm, nw, i, conv["rtf"][cond], conv["xtf"][cond], conv["busac_i"], conv["tm"][cond], Bool(conv["transformer"]), cond)
    end
end

function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    active_pole = first(_PM.ref(pm, nw, :convs_ac_cond, i))
    for cond in active_pole
        S = conv["Pacrated"][cond]
        P1 = cos(0) * S
        Q1 = sin(0) * S
        P2 = cos(pi) * S
        Q2 = sin(pi) * S
        constraint_conv_firing_angle(pm, nw, i, S, P1, Q1, P2, Q2, cond)
    end
end
