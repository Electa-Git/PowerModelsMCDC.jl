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
most of the parameters have the same meaning as in PowerModelsACDC. In particular, the
`status` parameter of `branchdc` and `convdc` components determines whether to include the
element in the model. If the component is active (i.e., `status = 1`),
additional parameters control the availability of the single conductors/poles of the
multi-conductor element. This guarantees portability with PowerModelsACDC.

The parameters that are introduced in PowerModelsMCDC are described below.


### Converter (`convdc`)

| Field         | Values  | Unit | Description                                             |
| :------------ | :-----: | :--: | :------------------------------------------------------ |
| `poles`       | {1,2}   |      | Number of poles:``\\``1: monopolar (symmetric or asymmetric)``\\``2: bipolar |
| `connect_at`  | {0,1,2} |      | Bus terminals where the converter is connected (only used if the converter is monopolar):``\\``0: positive and negative``\\``1: positive and neutral``\\``2: negative and neutral |
| `ground_type` | {0,1}   |      | Neutral terminal grounding type:``\\``0: ungrounded neutral terminal``\\``1: grounded neutral terminal |
| `ground_z`    | [0,+∞)  | p.u. | Grounding impedance (only used if `ground_type == 1`)   |
| `status_p`    | {0,1}   |      | Status of the converter pole connected to positive and neutral terminals:``\\``0: inactive``\\``1: active |
| `status_r`    | {0,1}   |      | Status of the converter pole connected to positive and negative terminals:``\\``0: inactive``\\``1: active |
| `status_n`    | {0,1}   |      | Status of the converter pole connected to neutral and negative terminals:``\\``0: inactive``\\``1: active |


### DC branch (`branchdc`)

| Field        | Values  | Unit | Description                                              |
| :----------- | :-----: | :--: | :------------------------------------------------------- |
| `conductors` | {2,3}   |      | Number of conductors, including metallic return          |
| `connect_at` | {0,1,2} |      | Bus terminals where the branch is connected (only used if the DC branch is monopolar):``\\``0: positive and negative``\\``1: positive and neutral``\\``2: negative and neutral |
| `return_z`   | (0,+∞)  | p.u. | Metallic return impedance                                |
| `status_p`   | {0,1}   |      | Status of the positive conductor:``\\``0: inactive``\\``1: active |
| `status_r`   | {0,1}   |      | Status of the metallic return:``\\``0: inactive``\\``1: active |
| `status_n`   | {0,1}   |      | Status of the negative conductor:``\\``0: inactive``\\``1: active |

The DC bus terminals, which the DC branch is connected to, determine which status parameters
are selected.


## Working with Matpower files

Input data can be provided in the form of a file structured similarly to the format defined
by Matpower.
An
[example `.m` file](https://github.com/Electa-Git/PowerModelsMCDC.jl/blob/master/test/data/case5_2grids_MC.m)
is available to illustrate the syntax.
You can provide such a file to PowerModelsMCDC by using the [`parse_file`](@ref) function.
