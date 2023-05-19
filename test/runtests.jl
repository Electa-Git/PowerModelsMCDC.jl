import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt
using Test

const _PMMCDC_dir = dirname(dirname(pathof(_PMMCDC))) # Root directory of PowerModelsMCDC package

nlp_optimizer = _PMMCDC.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)


@testset "PowerModelsMCDC" begin

    # Problems
    include("prob.jl")

end;
