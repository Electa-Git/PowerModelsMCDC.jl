# Problem specifications

Currently, PowerModelsMCDC only supports the OPF problem.


## OPF

The Optimal Power Flow (OPF) problem over a hybrid AC/DC network.

It uses a single-phase representation for the AC part, and a multi-conductor model for the
DC part.

To build and solve such a problem, use the [`solve_mcdcopf`](@ref) function.
