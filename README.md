# PowerModelsMCDC.jl

PowerModelsMCDC.jl is a Julia/JuMP/PowerModels package for hybrid AC/DC systems with multi-conductor model of the DC grid in order to represnt unbalanced HVDC grids. The positive and negative poles of bipolar converter stations are modelled separately and DC buses are modelled using three terminals, namely, the positive, the negative and the neutral terminal. Each conductor of a DC branch is modelled separately including the metallic return conductor and ground return.

## Contributors

Chandra Kant Jat (KU Leuven / EnergyVille): Main developer  
Jay Dave (KU Leuven / EnergyVille): Testing and validations  
Hakan Ergun (KU Leuven / EnergyVille): Supervisor 
