using Documenter, PowerModelsMCDC

makedocs(
    modules = [PowerModelsMCDC],
    sitename = "PowerModelsMCDC",
    warnonly = :missing_docs,
    pages = [
        "Home" => "index.md"
        "Manual" => [
            "Network data format" => "man/network-data.md"
            "Network formulations" => "man/formulations.md"
            "Problem specifications" => "man/specifications.md"
        ]
        "API" => [
            "Functions" => "api/functions.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Electa-Git/PowerModelsMCDC.jl.git"
)
