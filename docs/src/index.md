# PowerModelsMCDC.jl documentation


## Overview

[PowerModelsMCDC.jl](https://github.com/Electa-Git/PowerModelsMCDC.jl) is a Julia package
for the steady-state optimization of hybrid AC/DC power networks, with a focus on
multiconductor modeling of DC networks.

This package builds upon [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl),
which is used for modeling the AC system, and is similar to
[PowerModelsACDC.jl](https://github.com/Electa-Git/PowerModelsACDC.jl), which features a
single-conductor model of DC networks.

PowerModelsMCDC.jl is particularly suitable for representing unbalanced HVDC networks:

- DC buses are modeled using 3 terminals: positive, negative, and neutral.
- Each conductor of a DC branch is individually modeled, including the metallic return
  conductor.
- Both monopolar and bipolar converter stations are considered; in the latter case, the two
  poles are modeled separately.


## Installation

From Julia, PowerModelsMCDC can be installed using the built-in package manager:

```julia
using Pkg
Pkg.add("PowerModelsMCDC")
```


## Citing PowerModelsMCDC.jl

If you find PowerModelsMCDC.jl useful in your work, we kindly request that you cite the
following [preprint](https://arxiv.org/abs/2211.06283):

```bibtex
@misc{PowerModelsMCDC,
    doi = {10.48550/ARXIV.2211.06283},
    url = {https://arxiv.org/abs/2211.06283},
    author = {Jat, Chandra Kant and Dave, Jay and Van Hertem, Dirk and Ergun, Hakan},
    title = {Unbalanced OPF Modelling for Mixed Monopolar and Bipolar HVDC Grid Configurations},
    publisher = {arXiv},
    year = {2022},
    copyright = {Creative Commons Attribution 4.0 International}
}
```


## License

This code is provided under a
[BSD 3-Clause License](https://github.com/Electa-Git/PowerModelsMCDC.jl/blob/master/LICENSE.md).

