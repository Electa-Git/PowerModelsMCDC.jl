constraint_voltage_dc(pm::_PM.AbstractPowerModel) = constraint_voltage_dc(pm, pm.cnw)
# no data, so no further templating is needed, constraint goes directly to the formulations
function constraint_kcl_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
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

function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus_arcs_dcgrid = _PM.ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_convs_dc = _PM.ref(pm, nw, :bus_convs_dc, i)
    pd = _PM.ref(pm, nw, :busdc, i)["Pdc"]
    total_cond = _PM.ref(pm, nw, :busdc,i)["conductors"]
    constraint_kcl_shunt_dcgrid(pm, nw, i, bus_arcs_dcgrid, bus_convs_dc, pd, total_cond)
end
#
function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    total_cond = _PM.ref(pm, nw, :branchdc, i)["conductors"]

    p = _PM.ref(pm, nw, :dcpol)
    # display("p for bus $i is $p")
    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p, total_cond)
end
#
function constraint_converter_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
     # plmax = Dict([(i, []) for i in 1:conv["conductors"] ])
    for cond in 1:conv["conductors"]
          plmax = conv["LossA"][cond] + conv["LossB"][cond] * conv["Pacrated"][cond] + conv["LossCinv"][cond] * (conv["Pacrated"][cond])^2
        # push!(plmax[c], conv["LossA"][c] + conv["LossB"][c] * conv["Pacrated"][c] + conv["LossCinv"][c] * (conv["Pacrated"][c])^2 )
        constraint_converter_losses(pm, nw, i, a[cond], b[cond], c[cond], plmax, cond)
    end
end

function constraint_converter_dc_ground(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
        total_conv_cond=conv["conductors"]
        pconv_dc = _PM.var(pm, nw, :pconv_dc, i)
        pconv_dcg= _PM.var(pm, nw, :pconv_dcg, i)
        constraint_converter_dc_ground(pm, nw, i,pconv_dc, pconv_dcg, total_conv_cond)
end

function constraint_converter_dc_ground_shunt_kcl(pm::_PM.AbstractPowerModel, nw::Int=pm.cnw)
    # conv = _PM.ref(pm, nw, :convdc, i)
    #     total_conv_cond=conv["conductors"]
    #     pconv_dc = _PM.var(pm, nw, :pconv_dc, i)
    #     pconv_dcg= _PM.var(pm, nw, :pconv_dcg, i)
        # constraint_converter_dc_ground(pm, nw, i,pconv_dc, pconv_dcg, total_conv_cond)
        constraint_converter_dc_ground_shunt_kcl(pm, nw)
end

function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
    for cond in 1:conv["conductors"]
        Vmax = conv["Vmmax"][cond]
        Imax = conv["Imax"][cond]
        constraint_converter_current(pm, nw, i, Vmax, Imax,cond)
    end
end

function constraint_converter_dc_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    # conv = _PM.ref(pm, nw, :convdc, i)
    # for cond in 1:conv["conductors"]
    #     Vmax = conv["Vmmax"][cond]
    #     Imax = conv["Imax"][cond]
        constraint_converter_dc_current(pm, nw, i)
    # end
end

function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        # conv["index"][cond]
        constraint_active_conv_setpoint(pm, nw, i, conv["P_g"][cond], cond)
    end
end

function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
    display(i)
    for cond in 1:conv["conductors"]
        constraint_reactive_conv_setpoint(pm, nw, i, conv["Q_g"][cond], cond)
    end
end
""
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    # conv = _PM.ref(pm, nw, :convdc, i)

    # for cond in 1:conv["conductors"]
        # constraint_dc_voltage_magnitude_setpoint(pm, nw, conv["busdc_i"], conv["Vdcset"][cond], cond)
    # end
    constraint_dc_voltage_magnitude_setpoint(pm, nw, i)
end

#
function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        # display(conv["rc"][cond])
        # display(conv["xc"][cond])
        # display(conv["reactor"])
        constraint_conv_reactor(pm, nw, i, conv["rc"][cond], conv["xc"][cond], Bool(conv["reactor"]), cond)
    end
end

#
function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)

    for cond in 1:conv["conductors"]
        constraint_conv_filter(pm, nw, i, conv["bf"][cond], Bool(conv["filter"]), cond)
    end
end

#
function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
    # display("template")
    for cond in 1:conv["conductors"]
        # display(conv["rtf"][cond])
        # display(conv["xtf"][cond])
        # display(conv["busac_i"])
        #  display(conv["tm"][cond])
     constraint_conv_transformer(pm, nw, i, conv["rtf"][cond], conv["xtf"][cond], conv["busac_i"], conv["tm"][cond], Bool(conv["transformer"]), cond)
    end
end

#
function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
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

function constraint_dc_branch_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    vpu = 1;
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)

    ccm_max = (_PM.comp_start_value(_PM.ref(pm, nw, :branchdc, i), "rateA", 0.0) / vpu)^2

    p = _PM.ref(pm, nw, :dcpol)
    constraint_dc_branch_current(pm, nw, f_bus, f_idx, ccm_max, p)
end

function constraint_dc_droop_control(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    conv = _PM.ref(pm, nw, :convdc, i)
    bus = _PM.ref(pm, nw, :busdc, conv["busdc_i"])
    for cond in 1:conv["conductors"]
        constraint_dc_droop_control(pm, nw, i, conv["busdc_i"][cond], conv["Vdcset"][cond], conv["Pdcset"][cond], conv["droop"][cond], cond)
    end
end

# ############## TNEP Constraints #####################
# function constraint_voltage_dc_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw)
#     constraint_voltage_dc_ne(pm, nw)
# end
# # no data, so no further templating is needed, constraint goes directly to the formulations
# function constraint_kcl_shunt_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     bus = PowerModels.ref(pm, nw, :bus, i)
#     bus_arcs = PowerModels.ref(pm, nw, :bus_arcs, i)
#     bus_arcs_dc = PowerModels.ref(pm, nw, :bus_arcs_dc, i)
#     bus_gens = PowerModels.ref(pm, nw, :bus_gens, i)
#     bus_convs_ac = PowerModels.ref(pm, nw, :bus_convs_ac, i)
#     bus_convs_ac_ne = PowerModels.ref(pm, nw, :bus_convs_ac_ne, i)
#     bus_loads = PowerModels.ref(pm, nw, :bus_loads, i)
#     bus_shunts = PowerModels.ref(pm, nw, :bus_shunts, i)
#
#     pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
#     qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)
#
#     gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
#     bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
#     constraint_kcl_shunt_ne(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, pd, qd, gs, bs)
# end
#
# function constraint_converter_limit_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     bigM = 1.2
#     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#     pmax = conv["Pacrated"]
#     pmin = -conv["Pacrated"]
#     qmax = conv["Qacrated"]
#     qmin = -conv["Qacrated"]
#     pmaxdc = conv["Pacrated"] * bigM
#     pmindc = -conv["Pacrated"] * bigM
#     imax = conv["Imax"]
#
#     constraint_converter_limit_on_off(pm, nw, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
# end
#
# function constraint_kcl_shunt_dcgrid_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     bus_arcs_dcgrid = PowerModels.ref(pm, nw, :bus_arcs_dcgrid, i)
#     if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), i)
#         bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, i)
#     else
#         bus_arcs_dcgrid_ne = []
#     end
#     bus_convs_dc = PowerModels.ref(pm, nw, :bus_convs_dc, i)
#     bus_convs_dc_ne = PowerModels.ref(pm, nw, :bus_convs_dc_ne, i)
#     pd = PowerModels.ref(pm, nw, :busdc, i)["Pdc"]
#     constraint_kcl_shunt_dcgrid_ne(pm, nw, i, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
# end
#
# function constraint_kcl_shunt_dcgrid_ne_bus(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     bus_i = PowerModels.ref(pm, nw, :busdc_ne, i)["busdc_i"]
#     if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), bus_i)
#         bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, bus_i)
#     else
#         bus_arcs_dcgrid_ne = []
#     end
#     bus_ne_convs_dc_ne = PowerModels.ref(pm, nw, :bus_ne_convs_dc_ne, bus_i)
#     pd_ne = PowerModels.ref(pm, nw, :busdc_ne, i)["Pdc"]
#     constraint_kcl_shunt_dcgrid_ne_bus(pm, nw, i, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
# end
#
# function constraint_ohms_dc_branch_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     branch = PowerModels.ref(pm, nw, :branchdc_ne, i)
#     f_bus = branch["fbusdc"]
#     t_bus = branch["tbusdc"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)
#
#     p = PowerModels.ref(pm, nw, :dcpol)
#
#     constraint_ohms_dc_branch_ne(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p)
# end
#
# function constraint_branch_limit_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     branch = PowerModels.ref(pm, nw, :branchdc_ne, i)
#     f_bus = branch["fbusdc"]
#     t_bus = branch["tbusdc"]
#     f_idx = (i, f_bus, t_bus)
#     t_idx = (i, t_bus, f_bus)
#
#     pmax = branch["rateA"]
#     pmin = -branch["rateA"]
#     vpu = 0.8; #as taken in the variable creation
#     imax = (branch["rateA"]/0.8)^2
#     imin = 0
#     constraint_branch_limit_on_off(pm, nw, i, f_idx, t_idx, pmax, pmin, imax, imin)
# end
#
# #
# function constraint_converter_losses_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#     a = conv["LossA"]
#     b = conv["LossB"]
#     c = conv["LossCinv"]
#     plmax = conv["LossA"] + conv["LossB"] * conv["Imax"] + conv["LossCinv"] * (conv["Imax"])^2
#
#     constraint_converter_losses_ne(pm, nw, i, a, b, c, plmax)
# end
# #
#  function constraint_converter_current_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#      conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#      Vmax = conv["Vmmax"]
#      Imax = conv["Imax"]
#      constraint_converter_current_ne(pm, nw, i, Vmax, Imax)
#  end
#
# function constraint_conv_reactor_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#     constraint_conv_reactor_ne(pm, nw, i, conv["rc"], conv["xc"], Bool(conv["reactor"]))
# end
#
# #
# function constraint_conv_filter_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#     constraint_conv_filter_ne(pm, nw, i, conv["bf"], Bool(conv["filter"]) )
# end
#
# #
# function constraint_conv_transformer_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
#     constraint_conv_transformer_ne(pm, nw, i, conv["rtf"], conv["xtf"], conv["busac_i"], conv["tm"], Bool(conv["transformer"]))
# end
# #
# function constraint_conv_firing_angle_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#      conv = PowerModels.ref(pm, n, :convdc_ne, i)
#      S = conv["Pacrated"]
#      P1 = cos(0) * S
#      Q1 = sin(0) * S
#      P2 = cos(pi) * S
#      Q2 = sin(pi) * S
#      constraint_conv_firing_angle_ne(pm, n, i, S, P1, Q1, P2, Q2)
# end
