"""
    explicit_pf_data(file)

Load the existing numerical fixture and expose every converter control as an
explicit per-pole field accepted by the native MCDC power-flow API.
"""
function explicit_pf_data(file)
    data = _PMMCDC.parse_file(file)
    for converter in values(data["convdc"])
        poles = collect(keys(converter["status"]))
        converter["type_ac_poles"] =
            Dict(pole => converter["type_ac"] for pole in poles)
        converter["type_dc_poles"] =
            Dict(pole => converter["type_dc"] for pole in poles)
        converter["Vtar_poles"] =
            Dict(pole => converter["Vtar"] for pole in poles)
        for field in (
            "acq_droop",
            "kq_droop",
            "droop",
            "dVdcSet",
            "dVdcset",
        )
            converter[field] = 0.0
        end
        converter["islcc"] = 0
    end
    return data
end

@testset "MCDC power flow" begin
    file = joinpath(_PMMCDC_dir, "test/data/case5_2grids_MC.m")

    @testset "multiple converters at one AC bus" begin
        data = explicit_pf_data(file)
        data["convdc"]["2"]["busac_i"] = data["convdc"]["1"]["busac_i"]
        pm = _PM.instantiate_model(
            data,
            _PM.ACPPowerModel,
            _ -> nothing;
            ref_extensions=[_PMMCDC.add_ref_dcgrid!],
        )

        ac_bus = _PM.ref(pm, :convdc, 1, "busac_i")
        @test Set(keys(_PM.ref(pm, :bus_conv_poles, ac_bus))) ==
              Set((1, 2))
    end

    @testset "explicit pole controls and fixed voltage" begin
        data = explicit_pf_data(file)
        data["busdc"]["1"]["fixed_voltage"] = Dict("r" => 0.0)

        result = _PMMCDC.solve_mcdcpf(
            data,
            nlp_optimizer,
        )

        @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
        @test result["solution"]["busdc"]["1"]["vm"]["r"] ≈ 0.0 atol = 1e-8
    end

    @testset "native input validation" begin
        inactive = explicit_pf_data(file)
        inactive["convdc"]["1"]["status"]["p"] = 0
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            inactive,
            nlp_optimizer,
        )

        scalar_control = explicit_pf_data(file)
        delete!(scalar_control["convdc"]["1"], "type_ac_poles")
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            scalar_control,
            nlp_optimizer,
        )

        @test !applicable(
            _PMMCDC.solve_mcdcpf,
            scalar_control,
            _PM.DCPPowerModel,
            nlp_optimizer,
        )
    end

    @testset "unsupported converter controls" begin
        ac_droop = explicit_pf_data(file)
        ac_droop["convdc"]["1"]["acq_droop"] = 1
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            ac_droop,
            nlp_optimizer,
        )

        dc_droop = explicit_pf_data(file)
        dc_droop["convdc"]["1"]["droop"] = 0.05
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            dc_droop,
            nlp_optimizer,
        )

        unsupported_mode = explicit_pf_data(file)
        unsupported_mode["convdc"]["1"]["type_dc_poles"]["p"] = 3
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            unsupported_mode,
            nlp_optimizer,
        )

        lcc = explicit_pf_data(file)
        lcc["convdc"]["1"]["islcc"] = 1
        @test_throws ArgumentError _PMMCDC.solve_mcdcpf(
            lcc,
            nlp_optimizer,
        )
    end

    @testset "conflicting shared AC voltage targets" begin
        data = explicit_pf_data(file)
        first_converter = data["convdc"]["1"]
        second_converter = data["convdc"]["2"]
        second_converter["busac_i"] = first_converter["busac_i"]
        first_converter["Vtar_poles"] = Dict(
            pole => 1.0 for pole in keys(first_converter["status"])
        )
        second_converter["Vtar_poles"] = Dict(
            pole => 1.01 for pole in keys(second_converter["status"])
        )
        for pole in keys(first_converter["status"])
            first_converter["type_ac_poles"][pole] = 2
        end
        for pole in keys(second_converter["status"])
            second_converter["type_ac_poles"][pole] = 2
        end

        @test_throws ArgumentError _PM.instantiate_model(
            data,
            _PM.ACPPowerModel,
            _PMMCDC.build_mcdcpf;
            ref_extensions=[_PMMCDC.add_ref_dcgrid!],
        )
    end
end
