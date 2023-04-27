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


# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerModels)`
# NOTE: If this line is not included then the precompiled `_PM._LOGGER` won't be registered at runtime.
__init__() = Memento.register(_LOGGER)

# include("prob/mcdcopf.jl")

include("core/solution.jl")
include("core/data.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/objective.jl")
include("core/relaxation_scheme.jl")
# include("core/multi_conductor_functions.jl")
include("core/new_multi_conductor_functions.jl")
include("core/constraint_template.jl")
include("core/variable_mcdcgrid.jl")
include("core/variableconv_mc.jl")

include("formdcgrid/dcp.jl")
include("formconv/dcp.jl")

include("formdcgrid/acp.jl")
include("formconv/acp.jl")

# include("prob/acdcopf.jl")
include("prob/mcdcopf.jl")
include("prob/mcdcpf.jl")


# The following items are exported for user-friendlyness when calling
# `using PowerModelsMCDC`, so that users do not need to import JuMP to use a solver with
# PowerModelsMCDC.
import JuMP: optimizer_with_attributes
export optimizer_with_attributes

# TODO: after dropping support for JuMP 0.21, remove `.MOI` from the following line and from
# the @eval below.
import JuMP.MOI: TerminationStatusCode, ResultStatusCode
export TerminationStatusCode, ResultStatusCode


for status_code_enum in [TerminationStatusCode, ResultStatusCode]
    for status_code in instances(status_code_enum)
        @eval import JuMP.MOI: $(Symbol(status_code))
        @eval export $(Symbol(status_code))
    end
end

end
