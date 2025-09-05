# TO be completed when the package works


function constraint_converter_dc_current_new(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc::Int, terminals, busdc_terminal_conv_poles)
    for pole in poles
        pconv_dc = _PM.var(pm, n, :pconv_dc, i)[pole]
        pconv_dcg = _PM.var(pm, n, :pconv_dcg, i)[pole]
        iconv_dc = _PM.var(pm, n, :iconv_dc, i)[pole]
        iconv_dcg = _PM.var(pm, n, :iconv_dcg, i)[pole]
        vdcm = _PM.var(pm, n, :vdcm, busdc)[pole]


        for terminal in terminals
            for (conv_id,pole) in busdc_terminal_conv_poles["$busdc"][terminal]
                JuMP.@constraint(pm.model, pconv_dc[conv_id][pole] == iconv_dc[conv_id][pole] * vdcm[busdc][terminal])
            end
        end

        JuMP.@constraint(pm.model, pconv_dcg[i][pole] == iconv_dcg[i][pole] * vdcm[busdc]["n"])
        JuMP.@constraint(pm.model, iconv_dc[i][pole] + iconv_dcg[i][pole] == 0)
    end
    JuMP.@constraint(pm.model, sum(iconv_dc[i][pole] for pole in poles) == 0)
end