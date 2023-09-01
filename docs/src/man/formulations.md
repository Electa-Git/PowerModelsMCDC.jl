# Network formulations

The optimization problems defined in PowerModelsMCDC support two network formulations:

- `PowerModels.ACPPowerModel`;
- `PowerModels.DCPPowerModel`.

For an overview of the type hierarchy and details on how each formulation is defined over AC
networks, refer to
[PowerModels' “Network Formulations” documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/formulations/).

These formulations are extended in PowerModelsMCDC to include a multi-conductor model for DC
networks, as detailed below.


## `ACPPowerModel`

Class: NLP.

Variables: bus terminal voltage, branch conductor current.

Current flows in meshed DC networks follow Ohm's law, i.e., considering the resistance of
the DC branch conductors, and the DC branch conductors are lossy, according to Ohm's law.

Converters have parametric losses.


## `DCPPowerModel`

Class: LP.

Variables: bus terminal voltage, branch conductor current.

Current flows in a meshed DC network follow Ohm's law, i.e., considering the resistance of
branch conductors, but the DC branch conductors are lossless.

All DC voltages are defined up to a constant term. Therefore, the only meaningful use of the
voltage values provided in results is to compute voltage drops over DC branch conductors.

Converters have parametric losses (constant and linear terms only).
