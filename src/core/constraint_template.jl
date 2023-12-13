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

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs_dcgrid = _PM.ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_convs_dc = _PM.ref(pm, nw, :bus_convs_dc, i)
    pd = _PM.ref(pm, nw, :busdc, i)["Pdc"]
    total_cond = _PM.ref(pm, nw, :busdc, i)["conductors"]
    constraint_kcl_shunt_dcgrid(pm, nw, i, bus_arcs_dcgrid, bus_convs_dc, pd, total_cond)
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
    for cond in 1:conv["conductors"]
        plmax = conv["LossA"][cond] + conv["LossB"][cond] * conv["Pacrated"][cond] + conv["LossCinv"][cond] * (conv["Pacrated"][cond])^2
        constraint_converter_losses(pm, nw, i, a[cond], b[cond], c[cond], plmax, cond)
    end
end

function constraint_converter_dc_ground_shunt_ohm(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    constraint_converter_dc_ground_shunt_ohm(pm, nw)
end

function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    for cond in 1:conv["conductors"]
        Vmax = conv["Vmmax"][cond]
        Imax = conv["Imax"][cond]
        constraint_converter_current(pm, nw, i, Vmax, Imax, cond)
    end
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    constraint_converter_dc_current(pm, nw, i)
end

function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        constraint_active_conv_setpoint(pm, nw, i, conv["P_g"][cond], cond)
    end
end

function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    for cond in 1:conv["conductors"]
        constraint_reactive_conv_setpoint(pm, nw, i, conv["Q_g"][cond], cond)
    end
end
""
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    constraint_dc_voltage_magnitude_setpoint(pm, nw, i)
end

function constraint_ac_voltage_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    constraint_ac_voltage_setpoint(pm, nw, i)
end


function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        constraint_conv_reactor(pm, nw, i, conv["rc"][cond], conv["xc"][cond], Bool(conv["reactor"]), cond)
    end
end

function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        constraint_conv_filter(pm, nw, i, conv["bf"][cond], Bool(conv["filter"]), cond)
    end
end

function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    for cond in 1:conv["conductors"]
        constraint_conv_transformer(pm, nw, i, conv["rtf"][cond], conv["xtf"][cond], conv["busac_i"], conv["tm"][cond], Bool(conv["transformer"]), cond)
    end
end

function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    for cond in 1:conv["conductors"]
        S = conv["Pacrated"][cond]
        P1 = cos(0) * S
        Q1 = sin(0) * S
        P2 = cos(pi) * S
        Q2 = sin(pi) * S
        constraint_conv_firing_angle(pm, nw, i, S, P1, Q1, P2, Q2, cond)
    end

end


function constraint_dc_droop_control(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    bus = _PM.ref(pm, nw, :busdc, conv["busdc_i"])
    
    for cond in 1:conv["conductors"]
        constraint_dc_droop_control(pm, nw, i, conv["busdc_i"], conv["Vdcset"], conv["Pdcset"], conv["droop"], cond)
    end
end

function constraint_ac_droop_control(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    # bus = _PM.ref(pm, nw, :busdc, conv["busac_i"]) #verify
    
    for cond in 1:conv["conductors"]
        #modify the function inputs for ac-droop
        constraint_ac_droop_control(pm, nw, i, conv["busac_i"], conv["Vacset"], conv["Qacset"], conv["droop_ac"], cond)
    end
end