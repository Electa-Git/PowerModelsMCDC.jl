module PowerModelsMCDC


## Imports
import JuMP
import InfrastructureModels as _IM
import PowerModels as _PM
#import PowerModelsTopologicalActionsII as _PMTP
import PowerModelsACDC as _PMACDC
import Memento as _Memento

## Memento settings

# Create our module-level logger
const _LOGGER = _Memento.getlogger(@__MODULE__)

# Register the module-level logger at runtime
__init__() = _Memento.register(_LOGGER)


## Includes

include("core/data.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/objective.jl")
include("core/multiconductor.jl")
include("core/constraint_template.jl")
include("core/variable_mcdcgrid.jl")
include("core/variable_switching.jl")
include("core/variableconv_mc.jl")
include("core/solution.jl")

include("formdcgrid/dcp.jl")
include("formconv/dcp.jl")

include("formdcgrid/acp.jl")
include("formconv/acp.jl")

include("formdcgrid/lpac.jl")
include("formconv/lpac.jl")

include("prob/mcdcopf.jl")
include("prob/mcdcpf.jl")
include("prob/mcdc_acdcsw_AC.jl")
include("prob/mcdc_acdcsw_DC.jl")

include("io/parse.jl")


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
