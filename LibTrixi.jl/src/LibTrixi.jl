module LibTrixi

using OrdinaryDiffEq: OrdinaryDiffEq, step!, check_error, DiscreteCallback
using Trixi: Trixi, summary_callback, mesh_equations_solver_cache, nelements, nvariables,
             nnodes, wrap_array, eachelement, cons2prim, get_node_vars, eachnode
using MPI: MPI, run_init_hooks, set_default_error_handler_return
using Pkg

export trixi_initialize_simulation,
       trixi_initialize_simulation_cfptr,
       trixi_initialize_simulation_jl
export trixi_finalize_simulation,
       trixi_finalize_simulation_cfptr,
       trixi_finalize_simulation_jl
export trixi_calculate_dt,
       trixi_calculate_dt_cfptr,
       trixi_calculate_dt_jl
export trixi_is_finished,
       trixi_is_finished_cfptr,
       trixi_is_finished_jl
export trixi_step,
       trixi_step_cfptr,
       trixi_step_jl
export trixi_ndims,
       trixi_ndims_cfptr,
       trixi_ndims_jl
export trixi_nelements,
       trixi_nelements_cfptr,
       trixi_nelements_jl
export trixi_nvariables,
       trixi_nvariables_cfptr,
       trixi_nvariables_jl
export trixi_load_cell_averages,
       trixi_load_cell_averages_cfptr,
       trixi_load_cell_averages_jl
export trixi_version_julia,
       trixi_version_julia_cfptr,
       trixi_version_julia_jl
export trixi_version_julia_extended,
       trixi_version_julia_extended_cfptr,
       trixi_version_julia_extended_jl

export SimulationState, store_simstate, load_simstate, delete_simstate!


# global storage of name and version information of loaded packages
const _version_info = Ref("")
const _version_info_extended = Ref("")


include("simulationstate.jl")
include("api_c.jl")
include("api_jl.jl")


# Show debug output depending on environment variable
function show_debug_output()
    if !haskey(ENV, "LIBTRIXI_DEBUG")
        return false
    end

    if ENV["LIBTRIXI_DEBUG"] in ("all", "julia")
        return true
    else
        return false
    end
end


function assemble_version_info(; filter_expr = identity)
    packages = Pkg.dependencies() |> values |> collect |> filter_expr
    versions = String[]
    for p in sort(packages, by=x->x.name)
        if isnothing(p.version)
            push!(versions, p.name * " n/a")
        else
            push!(versions, p.name * " " * string(p.version))
        end
    end
    push!(versions, "Julia " * string(VERSION))
    join(versions, "\n")
end


function __init__()
    # MPI could have been initialized by an external application.
    # In this situation MPI.jl's MPI.Init is not called and leaves some package-internal
    # settings uninitialized. Recover those here.
    MPI.run_init_hooks()
    # Also make sure MPI returns errors, at least in debug mode
    if show_debug_output()
        MPI.set_default_error_handler_return()
    end

    # assemble packages information
    _version_info[] = assemble_version_info(filter_expr = filter(p -> p.is_direct_dep))
    _version_info_extended[] = assemble_version_info()
end

end # module LibTrixi
