export solve_mcdcpf, build_mcdcpf

const _MCDCPF_CONTROL_PQ = 1
const _MCDCPF_CONTROL_VOLTAGE = 2
const _MCDCPF_POLES = ("p", "n")
const _MCDCPF_POLE_FIELDS = (
    "type_ac_poles",
    "type_dc_poles",
    "Vtar_poles",
    "P_g",
    "Q_g",
    "Vdcset",
)
const _MCDCPF_DROOP_FIELDS = (
    "acq_droop",
    "kq_droop",
    "droop",
    "dVdcSet",
    "dVdcset",
)

"""
    _is_zero_control(value) -> Bool

Return whether a scalar or explicitly per-pole control parameter is zero.
Unsupported value types return `false` so validation reports them as active.
"""
_is_zero_control(value::Real) = iszero(value)
_is_zero_control(value::AbstractDict) = all(_is_zero_control, values(value))
_is_zero_control(::Any) = false

"""
    _pole_value(converter, converter_id, pole, field) -> Float64

Read and validate a finite numeric value from an explicit per-pole converter
dictionary.
"""
function _pole_value(
    converter::AbstractDict{String,<:Any},
    converter_id,
    pole::String,
    field::String,
)::Float64
    haskey(converter, field) ||
        throw(ArgumentError("converter $converter_id is missing `$field`"))
    pole_values = converter[field]
    pole_values isa AbstractDict ||
        throw(
            ArgumentError(
                "converter $converter_id field `$field` must be a per-pole dictionary",
            ),
        )
    haskey(pole_values, pole) ||
        throw(
            ArgumentError(
                "converter $converter_id is missing `$field[\"$pole\"]`",
            ),
        )
    value = pole_values[pole]
    value isa Real && isfinite(value) ||
        throw(
            ArgumentError(
                "converter $converter_id has invalid `$field[\"$pole\"]` value $value",
            ),
        )
    return Float64(value)
end

"""
    _pole_control_mode(converter, converter_id, pole, side) -> Int

Return the explicit AC or DC control mode for one converter pole. MCDC power
flow currently supports mode 1 (power control) and mode 2 (voltage control).
"""
function _pole_control_mode(
    converter::AbstractDict{String,<:Any},
    converter_id,
    pole::String,
    side::Symbol,
)::Int
    field =
        side === :ac ? "type_ac_poles" :
        side === :dc ? "type_dc_poles" :
        throw(ArgumentError("unknown converter side `$side`"))
    numeric_mode = _pole_value(converter, converter_id, pole, field)
    isinteger(numeric_mode) ||
        throw(
            ArgumentError(
                "converter $converter_id pole `$pole` has non-integer $side control mode $numeric_mode",
            ),
        )
    mode = Int(numeric_mode)
    mode in (_MCDCPF_CONTROL_PQ, _MCDCPF_CONTROL_VOLTAGE) ||
        throw(
            ArgumentError(
                "converter $converter_id pole `$pole` has unsupported $side control mode $mode",
            ),
        )
    return mode
end

"""
    _validate_converter_pf_data(converter, converter_id)

Validate the native, explicit converter fields accepted by `solve_mcdcpf`.
Inactive poles and converters must be omitted from the input data rather than
encoded with status zero.
"""
function _validate_converter_pf_data(
    converter::AbstractDict{String,<:Any},
    converter_id,
)
    get(converter, "islcc", 0) == 0 ||
        throw(
            ArgumentError(
                "converter $converter_id is an LCC; MCDC power flow supports VSC converters only",
            ),
        )

    status = get(converter, "status", nothing)
    status isa AbstractDict ||
        throw(
            ArgumentError(
                "converter $converter_id must provide an explicit per-pole `status` dictionary",
            ),
        )
    isempty(status) &&
        throw(ArgumentError("converter $converter_id has no active poles"))

    for (pole_value, active) in status
        pole = String(pole_value)
        pole in _MCDCPF_POLES ||
            throw(
                ArgumentError(
                    "converter $converter_id has unsupported active pole `$pole`",
                ),
            )
        active == 1 ||
            throw(
                ArgumentError(
                    "converter $converter_id pole `$pole` has status $active; omit inactive poles",
                ),
            )
        for field in _MCDCPF_POLE_FIELDS
            _pole_value(converter, converter_id, pole, field)
        end
        _pole_control_mode(converter, converter_id, pole, :ac)
        _pole_control_mode(converter, converter_id, pole, :dc)
    end

    for field in _MCDCPF_DROOP_FIELDS
        _is_zero_control(get(converter, field, 0.0)) ||
            throw(
                ArgumentError(
                    "converter $converter_id uses unsupported droop field `$field`",
                ),
            )
    end
    return nothing
end

"""
    _validate_mcdcpf_data(data)

Validate the single-network, native multi-conductor data contract before
PowerModels creates model references.
"""
function _validate_mcdcpf_data(data::Dict{String,Any})
    _IM.ismultinetwork(data) &&
        throw(ArgumentError("solve_mcdcpf does not support multinetwork data"))
    converters = get(data, "convdc", nothing)
    converters isa AbstractDict ||
        throw(ArgumentError("MCDC power-flow data must contain `convdc`"))
    for (converter_id, converter) in converters
        converter isa AbstractDict{String,<:Any} ||
            throw(
                ArgumentError(
                    "converter $converter_id must be a string-keyed dictionary",
                ),
            )
        _validate_converter_pf_data(converter, converter_id)
    end
    return nothing
end

"""
    solve_mcdcpf(data, optimizer; kwargs...)

Solve a feasibility power flow for native, explicit multi-conductor AC/DC
`data`. The data must already contain per-pole converter dictionaries and must
already have undergone any unit conversion required by the caller.

Only nonlinear ACP models, VSC converters, control modes 1/2, and single-network
data are supported. Keyword arguments are forwarded to `PowerModels.solve_model`.
"""
function solve_mcdcpf(
    data::Dict{String,Any},
    optimizer;
    kwargs...,
)
    _validate_mcdcpf_data(data)
    return _PM.solve_model(
        data,
        _PM.ACPPowerModel,
        optimizer,
        build_mcdcpf;
        ref_extensions=[add_ref_dcgrid!],
        kwargs...,
    )
end

"""
    _validate_supported_pf_controls(pm)

Validate converter controls after model references have been built. This also
protects callers that invoke `build_mcdcpf` through `instantiate_model`.
"""
function _validate_supported_pf_controls(pm::_PM.AbstractPowerModel)
    for (converter_id, converter) in _PM.ref(pm, :convdc)
        _validate_converter_pf_data(converter, converter_id)
    end
    return nothing
end

"""
    _ac_voltage_targets(pm) -> Dict{Int,Float64}

Collect one consistent AC-voltage target per bus from voltage-controlled
converter poles.
"""
function _ac_voltage_targets(
    pm::_PM.AbstractPowerModel,
)::Dict{Int,Float64}
    targets = Dict{Int,Float64}()
    sources = Dict{Int,Tuple{Int,String}}()
    for (converter_id, converter) in _PM.ref(pm, :convdc)
        bus = converter["busac_i"]
        bus isa Int ||
            throw(
                ArgumentError(
                    "converter $converter_id must connect to one integer AC bus, got $bus",
                ),
            )
        for pole_value in keys(converter["status"])
            pole = String(pole_value)
            _pole_control_mode(converter, converter_id, pole, :ac) ==
            _MCDCPF_CONTROL_VOLTAGE || continue
            target = _pole_value(
                converter,
                converter_id,
                pole,
                "Vtar_poles",
            )
            if haskey(targets, bus) &&
               !isapprox(targets[bus], target; atol=1e-10, rtol=1e-10)
                previous_id, previous_pole = sources[bus]
                throw(
                    ArgumentError(
                        "conflicting AC voltage targets at bus $bus: converter " *
                        "$previous_id pole `$previous_pole` requests $(targets[bus]), " *
                        "converter $converter_id pole `$pole` requests $target",
                    ),
                )
            end
            targets[bus] = target
            sources[bus] = (converter_id, pole)
        end
    end
    return targets
end

"""
    _constraint_ac_voltage_target(pm, bus, target)

Fix the AC voltage magnitude at `bus` to the converter target.
"""
function _constraint_ac_voltage_target(
    pm::_PM.AbstractPowerModel,
    bus::Int,
    target::Real,
)
    vm = _PM.var(pm, _PM.nw_id_default, :vm, bus)
    return JuMP.@constraint(pm.model, vm == target)
end

"""
    _constraint_fixed_dc_voltages(pm, bus, fixed)

Fix explicitly configured conductor-to-ground voltages at one DC bus.
"""
function _constraint_fixed_dc_voltages(
    pm::_PM.AbstractPowerModel,
    bus::Int,
    fixed::AbstractDict{String,<:Real},
)
    vdcm = _PM.var(pm, _PM.nw_id_default, :vdcm, bus)
    for (terminal, target) in fixed
        _has_axis_key(vdcm, terminal) ||
            throw(
                ArgumentError(
                    "DC bus $bus fixes unknown conductor terminal `$terminal`",
                ),
            )
        JuMP.@constraint(pm.model, vdcm[terminal] == target)
    end
    return nothing
end

"""
    _constraint_pole_dc_voltage(pm, converter_id, converter, pole, target)

Fix a pole voltage using `v[p] - v[r]` for the positive pole and
`v[r] - v[n]` for the negative pole.
"""
function _constraint_pole_dc_voltage(
    pm::_PM.AbstractPowerModel,
    converter_id,
    converter::AbstractDict{String,<:Any},
    pole::String,
    target::Real,
)
    vdcm = _PM.var(
        pm,
        _PM.nw_id_default,
        :vdcm,
        converter["busdc_i"],
    )
    if pole == "p"
        return JuMP.@constraint(
            pm.model,
            vdcm["p"] - vdcm["r"] == target,
        )
    elseif pole == "n"
        return JuMP.@constraint(
            pm.model,
            vdcm["r"] - vdcm["n"] == target,
        )
    end
    throw(
        ArgumentError(
            "converter $converter_id has unsupported active pole `$pole`",
        ),
    )
end

"""
    build_mcdcpf(pm::PowerModels.AbstractPowerModel)

Build an explicit multi-conductor feasibility power flow. The first functional
version supports nonlinear ACP models, VSC converters, power control (mode 1),
and voltage control (mode 2).
"""
function build_mcdcpf(pm::_PM.AbstractACPModel)
    _validate_supported_pf_controls(pm)

    # Power-flow variables are unbounded; component equations and fixed
    # setpoints determine the operating point.
    _PM.variable_bus_voltage(pm, bounded=false)
    _PM.variable_gen_power(pm, bounded=false)
    _PM.variable_branch_power(pm, bounded=false)
    variable_mc_dcbranch_current(pm, bounded=false)
    variable_mcdcgrid_voltage_magnitude(pm, bounded=false)
    variable_mcdc_converter(pm, bounded=false)

    # AC voltage targets shared by several poles must agree.
    _PM.constraint_model_voltage(pm)
    ac_voltage_targets = _ac_voltage_targets(pm)
    for (bus, target) in ac_voltage_targets
        _constraint_ac_voltage_target(pm, bus, target)
    end

    # One generator at each reference bus balances power. Additional generators
    # are fixed in deterministic ID order.
    for (bus_id, bus) in _PM.ref(pm, :ref_buses)
        bus["bus_type"] == 3 ||
            throw(
                ArgumentError(
                    "reference AC bus $bus_id does not have bus_type 3",
                ),
            )
        _PM.constraint_theta_ref(pm, bus_id)
        haskey(ac_voltage_targets, bus_id) ||
            _PM.constraint_voltage_magnitude_setpoint(pm, bus_id)

        generators = sort!(collect(_PM.ref(pm, :bus_gens, bus_id)))
        for generator in Iterators.drop(generators, 1)
            _PM.constraint_gen_setpoint_active(pm, generator)
            _PM.constraint_gen_setpoint_reactive(pm, generator)
        end
    end

    # Apply AC KCL and the normal PV-generator setpoints away from slack buses.
    reference_buses = Set(_PM.ids(pm, :ref_buses))
    for (bus_id, bus) in _PM.ref(pm, :bus)
        constraint_kcl_shunt(pm, bus_id)
        generators = sort!(collect(_PM.ref(pm, :bus_gens, bus_id)))
        if !isempty(generators) && !(bus_id in reference_buses)
            bus["bus_type"] == 2 ||
                throw(
                    ArgumentError(
                        "non-reference AC bus $bus_id with a generator must have bus_type 2",
                    ),
                )
            haskey(ac_voltage_targets, bus_id) ||
                _PM.constraint_voltage_magnitude_setpoint(pm, bus_id)
            for generator in generators
                _PM.constraint_gen_setpoint_active(pm, generator)
            end
        end
    end

    for branch_id in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, branch_id)
        _PM.constraint_ohms_yt_to(pm, branch_id)
    end

    # Fixed conductor voltages represent ideal boundaries, so KCL is omitted
    # only at those terminals and retained at every ordinary conductor node.
    for bus_id in _PM.ids(pm, :busdc)
        bus = _PM.ref(pm, :busdc, bus_id)
        fixed = get(bus, "fixed_voltage", Dict{String,Float64}())
        fixed isa AbstractDict{String,<:Real} ||
            throw(
                ArgumentError(
                    "DC bus $bus_id `fixed_voltage` must be a string-keyed numeric dictionary",
                ),
            )
        _constraint_fixed_dc_voltages(pm, bus_id, fixed)
        constraint_kcl_shunt_dcgrid(
            pm,
            bus_id;
            skip_terminals=keys(fixed),
        )
    end

    for branch_id in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, branch_id)
    end

    # Each pole independently chooses active-power or DC-voltage control and
    # reactive-power or AC-voltage control.
    for (converter_id, converter) in _PM.ref(pm, :convdc)
        constraint_conv_transformer(pm, converter_id)
        constraint_conv_reactor(pm, converter_id)
        constraint_conv_filter(pm, converter_id)

        for pole_value in keys(converter["status"])
            pole = String(pole_value)
            dc_mode = _pole_control_mode(
                converter,
                converter_id,
                pole,
                :dc,
            )
            if dc_mode == _MCDCPF_CONTROL_PQ
                active_power = _pole_value(
                    converter,
                    converter_id,
                    pole,
                    "P_g",
                )
                constraint_active_conv_setpoint(
                    pm,
                    _PM.nw_id_default,
                    converter_id,
                    active_power,
                    pole,
                )
            else
                voltage = _pole_value(
                    converter,
                    converter_id,
                    pole,
                    "Vdcset",
                )
                _constraint_pole_dc_voltage(
                    pm,
                    converter_id,
                    converter,
                    pole,
                    voltage,
                )
            end

            ac_mode = _pole_control_mode(
                converter,
                converter_id,
                pole,
                :ac,
            )
            if ac_mode == _MCDCPF_CONTROL_PQ
                reactive_power = _pole_value(
                    converter,
                    converter_id,
                    pole,
                    "Q_g",
                )
                constraint_reactive_conv_setpoint(
                    pm,
                    _PM.nw_id_default,
                    converter_id,
                    reactive_power,
                    pole,
                )
            end
        end

        constraint_converter_losses(pm, converter_id)
        constraint_converter_current(pm, converter_id)
        constraint_converter_dc_current(pm, converter_id)
    end

    constraint_converter_dc_ground_shunt_ohm(pm)
    return nothing
end
