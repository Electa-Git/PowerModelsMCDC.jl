# Test exported symbols

@testset "Base" begin

    @testset "add_ref_dcgrid!" begin

        # Absence of DC components must not result in errors
        @testset "AC-only network" begin
            _PM_dir = dirname(dirname(pathof(_PM))) # Root directory of PowerModels package
            # Smallest test case in _PM suitable for an OPF and not including dclines
            file = joinpath(_PM_dir, "test/data/matpower/case5.m")
            result = _PMMCDC.solve_mcdcopf(file, _PM.ACPPowerModel, nlp_optimizer)

            @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
            @test result["objective"] ≈ 18269.1 rtol = 1e-3
        end
    end
end
