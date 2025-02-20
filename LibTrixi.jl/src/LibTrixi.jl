module LibTrixi

using OrdinaryDiffEq: OrdinaryDiffEq, step!, check_error, DiscreteCallback
using Trixi: Trixi, summary_callback, mesh_equations_solver_cache, ndims, nelements,
             nelementsglobal, ndofs, ndofsglobal, nvariables, nnodes, wrap_array,
             eachelement, cons2prim, get_node_vars, eachnode
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
export trixi_nelementsglobal,
       trixi_nelementsglobal_cfptr,
       trixi_nelementsglobal_jl
export trixi_ndofs,
       trixi_ndofs_cfptr,
       trixi_ndofs_jl
export trixi_ndofsglobal,
       trixi_ndofsglobal_cfptr,
       trixi_ndofsglobal_jl
export trixi_ndofselement,
       trixi_ndofselement_cfptr,
       trixi_ndofselement_jl
export trixi_nvariables,
       trixi_nvariables_cfptr,
       trixi_nvariables_jl
export trixi_nnodes,
       trixi_nnodes_cfptr,
       trixi_nnodes_jl
export trixi_load_node_reference_coordinates,
       trixi_load_node_reference_coordinates_cfptr,
       trixi_load_node_reference_coordinates_jl
export trixi_load_node_weights,
       trixi_load_node_weights_cfptr,
       trixi_load_node_weights_jl
export trixi_load_primitive_vars,
       trixi_load_primitive_vars_cfptr,
       trixi_load_primitive_vars_jl
export trixi_load_element_averaged_primitive_vars,
       trixi_load_element_averaged_primitive_vars_cfptr,
       trixi_load_element_averaged_primitive_vars_jl
export trixi_register_data,
       trixi_register_data_cfptr,
       trixi_register_data_jl
export trixi_version_library,
       trixi_version_library_cfptr,
       trixi_version_library_jl
export trixi_version_library_major,
       trixi_version_library_major_cfptr,
       trixi_version_library_major_jl
export trixi_version_library_minor,
       trixi_version_library_minor_cfptr,
       trixi_version_library_minor_jl
export trixi_version_library_patch,
       trixi_version_library_patch_cfptr,
       trixi_version_library_patch_jl
export trixi_version_julia,
       trixi_version_julia_cfptr,
       trixi_version_julia_jl
export trixi_version_julia_extended,
       trixi_version_julia_extended_cfptr,
       trixi_version_julia_extended_jl
export trixi_get_t8code_forest,
       trixi_get_t8code_forest_cfptr,
       trixi_get_t8code_forest_jl
export trixi_get_p4est_mesh,
       trixi_get_p4est_mesh_cfptr,
       trixi_get_p4est_mesh_jl
export trixi_get_p8est_mesh,
       trixi_get_p8est_mesh_cfptr,
       trixi_get_p8est_mesh_jl
export trixi_eval_julia,
       trixi_eval_julia_cfptr,
       trixi_eval_julia_jl
export trixi_get_simulation_time,
       trixi_get_simulation_time_cfptr,
       trixi_get_simulation_time_jl

export SimulationState, store_simstate, load_simstate, delete_simstate!
export LibTrixiDataRegistry


# global storage of name and version information of loaded packages
function assemble_version_info(; filter_expr = p -> true, include_julia = true)
    packages = filter(filter_expr, Pkg.dependencies() |> values |> collect)
    versions = String[]
    found_libtrixi = false
    for p in packages
        if isnothing(p.version)
            push!(versions, p.name * " n/a")
        else
            push!(versions, p.name * " " * string(p.version))
        end
        if p.name == "LibTrixi"
            found_libtrixi = true
        end
    end

    # When running Julia with the LibTrixi package dir as the active project,
    # Pkg.dependencies() will not return LibTrixi itself, which is remedied here
    if !found_libtrixi && Pkg.project().name == "LibTrixi"
        push!(versions, "LibTrixi " * string(Pkg.project().version))
    end

    sort!(versions)

    # Add Julia version
    if include_julia
        push!(versions, "julia " * string(VERSION))
    end

    return join(versions, "\n")
end

const _version_info = assemble_version_info(filter_expr = p -> p.is_direct_dep)
const _version_info_extended = assemble_version_info()
const _version_libtrixi = begin
    libtrixi_string = assemble_version_info(filter_expr = p -> p.name == "LibTrixi",
                                            include_julia = false)

    # When running Julia with the LibTrixi package dir as the active project,
    # Pkg.dependencies() will not return LibTrixi itself, which is remedied here
    if isempty(libtrixi_string)
        version_string = string(Pkg.project().version)
    else
        version_string = split(libtrixi_string, " ")[2]
    end

    version_string
end


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


function __init__()
    # MPI could have been initialized by an external application.
    # In this situation MPI.jl's MPI.Init is not called and leaves some package-internal
    # settings uninitialized. Recover those here.
    MPI.run_init_hooks()
    # Also make sure MPI returns errors, at least in debug mode
    if show_debug_output()
        MPI.set_default_error_handler_return()
    end
end

end # module LibTrixi
