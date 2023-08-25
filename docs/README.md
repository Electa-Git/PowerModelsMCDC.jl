# Documentation for PowerModelsMCDC.jl

You can read this documentation online at
<https://electa-git.github.io/PowerModelsMCDC.jl/dev/>.

## Preview the documentation (for developers)

While developing PowerModelsMCDC.jl you can preview the documentation locally in your
browser with live-reload capability, i.e., when modifying a file, every browser (tab)
currently displaying the corresponding page is automatically refreshed.

### Instructions for *nix

1. Copy the following zsh/Julia code snippet:

   ```julia
   #!/bin/zsh
   #= # The following line is zsh code
   julia -i $0:a # The string `$0:a` represents this file in zsh
   =# # Following lines are Julia code
   import Pkg
   Pkg.activate(; temp=true)
   Pkg.develop("PowerModelsMCDC")
   Pkg.add("Documenter")
   Pkg.add("LiveServer")
   using PowerModelsMCDC, LiveServer
   cd(dirname(dirname(pathof(PowerModelsMCDC))))
   servedocs()
   exit()
   ```

2. Save it as a zsh script (name it like `preview_powermodelsmcdc_docs.sh`).
3. Assign execute permission to the script: `chmod u+x preview_powermodelsmcdc_docs.sh`.
4. Run the script.
5. Open your favorite web browser and navigate to `http://localhost:8000`.
