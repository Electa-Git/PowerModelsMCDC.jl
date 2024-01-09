# PowerModelsMCDC.jl

[![CI](https://github.com/Electa-Git/PowerModelsMCDC.jl/workflows/CI/badge.svg)](https://github.com/Electa-Git/PowerModelsMCDC.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Electa-Git/PowerModelsMCDC.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Electa-Git/PowerModelsMCDC.jl)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://electa-git.github.io/PowerModelsMCDC.jl/dev/)

PowerModelsMCDC.jl is a Julia/JuMP/PowerModels package for hybrid AC/DC systems with multiconductor model of the DC grid in order to represent unbalanced HVDC grids. The positive and negative poles of bipolar converter stations are modeled separately, and DC buses are modeled using three terminals: the positive, negative, and neutral terminal. Each conductor of a DC branch is modeled separately, including the metallic return conductor and converter grounding.

## Core Problem Specification
* Non-linear AC/DC optimal power flow (OPF) model with multiconductor DC.
* Only ACP and DCP formulations are complete. Convex relaxations are currently under development.

### Other problems (to be added to this package)
* AC/DC SCOPF with multiconductor DC (MCDC SCOPF): complete, and planned to be added soon.
* AC/DC power flow with different converter control modes: complete, and planned to be added soon.
* Transmission network expansion planning with mixed monopolar and bipolar HVDC configurations: work in progress.
## Contributors

* Chandra Kant Jat (KU Leuven / EnergyVille): main developer
* Jay Dave (KU Leuven / EnergyVille): testing and validations
* Hakan Ergun (KU Leuven / EnergyVille): supervisor
* Matteo Rossini (KU Leuven / EnergyVille): continuous integration
* Matteo Baù (RSE) : DCP formulation and component status

## Citing PowerModelsMCDC

If you find PowerModelsMCDC useful in your work, we kindly request that you cite the following publications:
[MCDC OPF](https://ieeexplore.ieee.org/document/10304389):

```bibtex
@ARTICLE{10304389,
  author={Jat, Chandra Kant and Dave, Jay and Van Hertem, Dirk and Ergun, Hakan},
  journal={IEEE Transactions on Power Systems}, 
  title={Hybrid AC/DC OPF Model for Unbalanced Operation of Bipolar HVDC Grids},
  year={2023},
  volume={},
  number={},
  pages={1-11},
  doi={10.1109/TPWRS.2023.3329345}}
```

## Contact Details
If you have something to discuss about the package or related work please feel free to reach out at [chandrakant.jat@kuleuven.be](mailto:chandrakant.jat@kuleuven.be).

## License

This code is provided under a [BSD 3-Clause License](/LICENSE.md).
