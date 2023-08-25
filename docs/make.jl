using Documenter, PowerModelsMCDC

makedocs(
    modules     = [PowerModelsMCDC],
    format      = Documenter.HTML(mathengine = Documenter.MathJax()),
    sitename    = "PowerModelsMCDC.jl",
    authors     = "Chandra Kant Jat, Hakan Ergun, Jay Dave",
    pages       = [
              "Home"    => "index.md",
                 ]
)

deploydocs(
     repo = "github.com/Electa-Git/PowerModelsMCDC.jl.git"
)
