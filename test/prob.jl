# Test problem functions

# The purpose of the tests contained in this file is to detect if anything has accidentally
# changed in the problem functions. Accordingly, only termination status and objective value
# are tested.
# For testing specific features, it is better to write ad-hoc tests in separate files.

@testset "Problem" begin

    @testset "mcdcopf" begin
        @testset "case5_2grids_MC" begin

            # ==============================================================================
            # TODO: The function below is copied with minor edits from
            # `test/scripts/opf_acp.jl` and is used here to manipulate the input data in
            # order to produce the intended result. However, this function should be removed
            # from this file as soon as possible. In fact:
            # - Modifications to the input data that are test-case-specific should be made
            #   directly in the input data file.
            # - Modifications that are to be systematically applied to the input data based
            #   on the value of certain parameters should be put in a new function in
            #   `src/io/`, which should not contain test-case-specific modifications.
            function build_mc_data!(base_data)
                mp_data = _PM.parse_file(base_data)

                for (c, conv) in mp_data["convdc"]
                    if conv["conv_confi"] == 2
                        conv["rtf"] = 2 * conv["rtf"]
                        conv["xtf"] = 2 * conv["xtf"]
                        conv["bf"] = 0.5 * conv["bf"]
                        conv["rc"] = 2 * conv["rc"]
                        conv["xc"] = 2 * conv["xc"]
                        conv["LossB"] = conv["LossB"]
                        conv["LossA"] = 0.5 * conv["LossA"]
                        conv["LossCrec"] = 2 * conv["LossCrec"]
                        conv["LossCinv"] = 2 * conv["LossCinv"]
                    end
                end

                _PMMCDC.process_additional_data!(mp_data)
                _PMMCDC._make_multiconductor_new!(mp_data)

                # Adjust line limits
                for (c, bn) in mp_data["branchdc"]
                    if bn["line_confi"] == 2
                        bn["rateA"] = bn["rateA"] / 2
                        bn["rateB"] = bn["rateB"] / 2
                        bn["rateC"] = bn["rateC"] / 2
                    end
                    metallic_cond_number = bn["conductors"]
                    bn["return_z"] = 0.052 # adjust metallic resistance
                    bn["r"][metallic_cond_number] = bn["return_z"]
                end

                # Adjust converter limits
                for (c, conv) in mp_data["convdc"]
                    if conv["conv_confi"] == 2
                        conv["Pacmax"] = conv["Pacmax"] / 2
                        conv["Pacmin"] = conv["Pacmin"] / 2
                        conv["Pacrated"] = conv["Pacrated"] / 2
                    end
                end

                # Adjust metallic return bus voltage limits
                for (i, busdc) in mp_data["busdc"]
                    busdc["Vdcmax"][3] = 0.1
                    busdc["Vdcmin"][3] = -0.1
                    busdc["Vdcmax"][2] = -0.9
                    busdc["Vdcmin"][2] = -1.1
                end
                return mp_data
            end

            data = build_mc_data!(joinpath(_PMMCDC_dir, "test/data/matacdc_scripts/case5_2grids_MC.m"))
            # End TODO =====================================================================

            result = _PMMCDC.run_mcdcopf(data, _PM.ACPPowerModel, nlp_optimizer)

            @test result["termination_status"] == _PMMCDC.LOCALLY_SOLVED
            @test result["objective"] ≈ 869.1 rtol = 1e-3
        end
    end
end
