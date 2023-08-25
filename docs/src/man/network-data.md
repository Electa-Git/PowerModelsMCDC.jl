# Network data format

```@meta
CurrentModule = PowerModelsMCDC

# In this documentation, we use LaTeX newlines (i.e., ``\\``) to achieve line breaks in
# table cells.
# It is a clumsy trick, and what is worse, it inserts tons of boilerplate code in the HTML,
# instead of just a <br /> tag. As an alternative, tables could be directly coded in HTML.
```


## The network data dictionary

Since PowerModelsMCDC extends the
[PowerModelsACDC data format](https://electa-git.github.io/PowerModelsACDC.jl/dev/parser/),
most of the parameters have the same meaning as in PowerModelsACDC.
The remaining parameters are described below.


### Converter (`convdc`)

| Field         | Values  | Data U.M. | Description                                        |
| :------------ | :-----: | :-------: | :------------------------------------------------- |
| `conv_confi`  | {1,2}   |           | Configuration:``\\``1: monopolar (symmetric or asymmetric)``\\``2: bipolar |
| `connect_at`  | {0,1,2} |           | Bus terminals where the converter is connected (only used if the converter is monopolar):``\\``0: positive and negative``\\``1: positive and neutral``\\``2: negative and neutral |
| `ground_type` | {0,1}   |           | Neutral terminal grounding type:``\\``0: ungrounded neutral terminal``\\``1: grounded neutral terminal |
| `ground_z`    | [0,+∞)  | p.u.      | Grounding impedance (only used if `ground_type == 1`) |


### DC branch (`branchdc`)

| Field         | Values  | Data U.M. | Description                                        |
| :------------ | :-----: | :-------: | :------------------------------------------------- |
| `line_confi`  | {1,2}   |           | Configuration:``\\``1: monopolar (symmetric or asymmetric)``\\``2: bipolar |
| `connect_at`  | {0,1,2} |           | Bus terminals where the branch is connected (only used if the DC branch is monopolar):``\\``0: positive and negative``\\``1: positive and neutral``\\``2: negative and neutral |
| `return_type` |         |           | **Not used in package code, but present in input files.**``\\``Originally meant for modeling ground return (1) instead of metallic return (2). |
| `return_z`    | (0,+∞)  | p.u.      | Metallic return impedance                          |


## Working with Matpower files

Input data can be provided in the form of a file structured similarly to the format defined
by Matpower.
An
[example `.m` file](https://github.com/Electa-Git/PowerModelsMCDC.jl/blob/master/test/data/matacdc_scripts/case5_2grids_MC.m)
is available to illustrate the syntax.
You can provide such a file to PowerModelsMCDC by using the [`parse_file`](@ref) function.
