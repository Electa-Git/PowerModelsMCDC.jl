# PowerModelsMCDC.jl

PowerModelsMCDC.jl is a Julia/JuMP/PowerModels package for hybrid AC/DC systems with multi-conductor model of the DC grid in order to represnt unbalanced HVDC grids. The positive and negative poles of bipolar converter stations are modelled separately and DC buses are modelled using three terminals, namely, the positive, the negative and the neutral terminal. Each conductor of a DC branch is modelled separately including the metallic return conductor and ground return.

## Contributors

Chandra Kant Jat (KU Leuven / EnergyVille): Main developer  
Jay Dave (KU Leuven / EnergyVille): Testing and validations  
Hakan Ergun (KU Leuven / EnergyVille): Supervisor 

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
If you have something to discuss about the package or related work please feel to reach out at [chandrakant.jat@kuleuven.be](chandrakant.jat@kuleuven.be).

## License
This code is provided under a BSD license.
