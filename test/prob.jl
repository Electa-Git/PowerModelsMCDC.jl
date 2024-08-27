# Test problem functions

# The purpose of the tests contained in this file is to detect if anything has accidentally
# changed in the problem functions. Accordingly, only termination status and objective value
# are tested.
# For testing specific features, it is better to write ad-hoc tests in separate files.

@testset "Problem" begin

    @testset "mcdcopf ACP" begin
        @testset "case5_2grids_MC" begin

            file = joinpath(_PMMCDC_dir, "test/data/matacdc_scripts/case5_2grids_MC.m")
            result = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, nlp_optimizer)

            @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
            @test result["objective"] ≈ 869.1 rtol = 1e-3
        end
    end

    @testset "mcdcopf ACR" begin
        @testset "case5_2grids_MC" begin

            file = joinpath(_PMMCDC_dir, "test/data/matacdc_scripts/case5_2grids_MC.m")
            result = _PMMCDC.solve_mcdcopf(file, _PM.ACRPowerModel, nlp_optimizer)

            @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
            @test result["objective"] ≈ 869.1 rtol = 1e-3
        end
    end

    @testset "mcdcopf DCP" begin
        @testset "case5_2grids_MC" begin

            file = joinpath(_PMMCDC_dir, "test/data/matacdc_scripts/case5_2grids_MC.m")
            result_dcp = _PMMCDC.solve_mcdcopf(file, _PM.DCPPowerModel, lp_optimizer)
            @test result_dcp["termination_status"] == _PMMCDC.OPTIMAL
            @test result_dcp["objective"] ≈ 823.0 rtol = 1e-3
        end
    end
end
