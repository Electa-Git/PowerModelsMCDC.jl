module PowerModelsMCDC


## Imports

import Memento
import JuMP
import InfrastructureModels as _IM
import PowerModels as _PM


## Memento settings

# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerModelsMCDC)`
# NOTE: If this line is not included then the precompiled `PowerModelsMCDC._LOGGER` won't be registered at runtime.
__init__() = Memento.register(_LOGGER)


## Includes

include("core/solution.jl")
include("core/data.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/objective.jl")
include("core/multiconductor.jl")
include("core/constraint_template.jl")
include("core/variable_mcdcgrid.jl")
include("core/variableconv_mc.jl")

include("formdcgrid/dcp.jl")
include("formconv/dcp.jl")

include("formdcgrid/acp.jl")
include("formconv/acp.jl")

include("prob/mcdcopf.jl")

## Exports

# The following items are exported for user-friendlyness when calling
# `using PowerModelsMCDC`, so that users do not need to import JuMP to use a solver with
# PowerModelsMCDC.
import JuMP: optimizer_with_attributes
export optimizer_with_attributes

import JuMP: TerminationStatusCode, ResultStatusCode
export TerminationStatusCode, ResultStatusCode

for status_code_enum in [TerminationStatusCode, ResultStatusCode]
    for status_code in instances(status_code_enum)
        @eval import JuMP: $(Symbol(status_code))
        @eval export $(Symbol(status_code))
    end
end

end
