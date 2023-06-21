# Test problem functions

# The purpose of the tests contained in this file is to detect if anything has accidentally
# changed in the problem functions. Accordingly, only termination status and objective value
# are tested.
# For testing specific features, it is better to write ad-hoc tests in separate files.

@testset "Problem" begin

    @testset "mcdcopf" begin
        @testset "case5_2grids_MC" begin

            file=joinpath(_PMMCDC_dir, "test/data/matacdc_scripts/case5_2grids_MC.m")
            result = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, nlp_optimizer)

            @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
            @test result["objective"] ≈ 869.1 rtol = 1e-3
        end
    end
end
