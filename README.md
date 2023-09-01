# PowerModelsMCDC.jl

[![CI](https://github.com/Electa-Git/PowerModelsMCDC.jl/workflows/CI/badge.svg)](https://github.com/Electa-Git/PowerModelsMCDC.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Electa-Git/PowerModelsMCDC.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Electa-Git/PowerModelsMCDC.jl)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://electa-git.github.io/PowerModelsMCDC.jl/dev/)

PowerModelsMCDC.jl is a Julia/JuMP/PowerModels package for hybrid AC/DC systems with multiconductor model of the DC grid in order to represent unbalanced HVDC grids. The positive and negative poles of bipolar converter stations are modeled separately, and DC buses are modeled using three terminals: the positive, the negative, and the neutral terminal. Each conductor of a DC branch is modeled separately, including the metallic return conductor and converter grounding.

## Core Problem Specification
* Non-linear AC/DC optimal power flow (OPF) model with multiconductor DC.
* Only ACP formulation is complete. DCP and convex relaxations are currently under development.

### Other problems (to be added in this package)
* AC/DC SCOPF with multiconductor DC (MCDC SCOPF): Complete and planned to be added soon.
* Transmission network expansion planning with mixed monopolar and bipolar HVDC configurations: Complete.
* AC/DC power flow with different converter control modes: Under development.
## Contributors

* Chandra Kant Jat (KU Leuven / EnergyVille): Main developer
* Jay Dave (KU Leuven / EnergyVille): Testing and validations
* Hakan Ergun (KU Leuven / EnergyVille): Supervisor

## Citing PowerModelsMCDC

If you find PowerModelsMCDC useful in your work, we kindly request that you cite the following publications:
[MCDC OPF](https://arxiv.org/abs/2211.06283):

```
@misc{mcdc_opf,
  doi = {10.48550/ARXIV.2211.06283},
  url = {https://arxiv.org/abs/2211.06283},
  author = {Jat, Chandra Kant and Dave, Jay and Van Hertem, Dirk and Ergun, Hakan},
  title = {Unbalanced OPF Modelling for Mixed Monopolar and Bipolar HVDC Grid Configurations},
  publisher = {arXiv},
  year = {2022},
  copyright = {Creative Commons Attribution 4.0 International}
}
```

## Contact Details
If you have something to discuss about the package or related work please feel free to reach out at [chandrakant.jat@kuleuven.be](chandrakant.jat@kuleuven.be).

## License

This code is provided under a [BSD 3-Clause License](/LICENSE.md).
