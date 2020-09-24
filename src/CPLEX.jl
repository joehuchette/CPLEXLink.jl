module CPLEX

const _DEPS_FILE = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("CPLEX not properly installed. Please run Pkg.build(\"CPLEX\")")
end

using CEnum
import SparseArrays

include("gen/ctypes.jl")
include("gen/libcpx_common.jl")
include("gen/libcpx_api.jl")

const _CPLEX_VERSION = VersionNumber(
    "$(CPX_VERSION_VERSION).$(CPX_VERSION_RELEASE).$(CPX_VERSION_MODIFICATION)"
)

if !(v"12.10.0" <= _CPLEX_VERSION < v"12.11")
    error(
        "You have installed version $_CPLEX_VERSION of CPLEX, which is not " *
        "supported by CPLEX.jl. If the version change was breaking, changes " *
        "may need to be made to the Julia code. Please open an issue at " *
        "https://github.com/jump-dev/CPLEX.jl."
    )
end

include("MOI/MOI_wrapper.jl")
include("MOI/MOI_callbacks.jl")
include("MOI/conflicts.jl")
include("MOI/indicator_constraint.jl")

# CPLEX exports all `CPXxxx` symbols. If you don't want all of these symbols in
# your environment, then use `import CPLEX` instead of `using CPLEX`.

for sym in names(@__MODULE__, all=true)
    sym_string = string(sym)
    if startswith(sym_string, "CPX")
        @eval export $sym
    end
end

include("deprecated_functions.jl")

end
