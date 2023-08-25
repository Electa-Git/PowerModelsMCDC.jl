"""
    parse_file(file; <keyword arguments>)

Parse a Matpower .m `file` into a PowerModelsMCDC data structure.

Keyword arguments, if any, are forwarded to `PowerModels.parse_file`.
"""
function parse_file(file::String; kwargs...)
    data = _PM.parse_file(file; kwargs...)
    build_mc_data!(data)
    return data
end
