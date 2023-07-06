import PowerModels as _PM
import PowerModelsMCDC as _PMMCDC
import Ipopt
import HiGHS
import Memento
using Test


# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(_PM), "error")
Memento.setlevel!(Memento.getlogger(_PMMCDC), "error")

const _PMMCDC_dir = dirname(dirname(pathof(_PMMCDC))) # Root directory of PowerModelsMCDC package

nlp_optimizer = _PMMCDC.optimizer_with_attributes(
    Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0, "sb" => "yes"
)
lp_optimizer = _PMMCDC.optimizer_with_attributes(
    HiGHS.Optimizer, "output_flag" => false
)


@testset "PowerModelsMCDC" begin

    # Problems
    include("prob.jl")

    # Exported symbols
    include("export.jl")

end;
