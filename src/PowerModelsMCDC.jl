isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsMCDC

# import Compat
import JuMP
import Memento
import PowerModels
# import PowerModelsACDC
const _PM = PowerModels
# const _PMACDC = PowerModelsACDC
import InfrastructureModels
# import InfrastructureModels: ids, ref, var, con, sol, nw_ids, nws, optimize_model!, @im_fields
const _IM = InfrastructureModels

import JuMP: with_optimizer
export with_optimizer

# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerModels)`
# NOTE: If this line is not included then the precompiled `_PM._LOGGER` won't be registered at runtime.
__init__() = Memento.register(_LOGGER)

include("prob/mcdcopf.jl")

include("core/solution.jl")
include("core/data.jl")
include("core/variabledcgrid.jl")
include("core/variableconv.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/objective.jl")
include("core/relaxation_scheme.jl")
include("core/multi_conductor_functions.jl")
include("core/new_multi_conductor_functions.jl")
include("core/constraint_template.jl")
include("core/variable_mcdcgrid.jl")

include("formdcgrid/dcp.jl")
include("formconv/dcp.jl")

include("prob/acdcopf.jl")
include("prob/mcdcopf.jl")

end
