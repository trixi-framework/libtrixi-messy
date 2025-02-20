############################################################################################
# Version information                                                                      #
############################################################################################

"""
    trixi_version_library_major()::Cint

Return major version number of libtrixi.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_library_major end

Base.@ccallable function trixi_version_library_major()::Cint
    return VersionNumber(_version_libtrixi).major
end

trixi_version_library_major_cfptr() = @cfunction(trixi_version_library_major, Cint, ())


"""
    trixi_version_library_minor()::Cint

Return minor version number of libtrixi.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_library_minor end

Base.@ccallable function trixi_version_library_minor()::Cint
    return VersionNumber(_version_libtrixi).minor
end

trixi_version_library_minor_cfptr() = @cfunction(trixi_version_library_minor, Cint, ())


"""
    trixi_version_library_patch()::Cint

Return patch version number of libtrixi.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_library_patch end

Base.@ccallable function trixi_version_library_patch()::Cint
    return VersionNumber(_version_libtrixi).patch
end

trixi_version_library_patch_cfptr() = @cfunction(trixi_version_library_patch, Cint, ())


"""
    trixi_version_library()::Cstring

Return full version string of libtrixi.

The return value is a read-only pointer to a NULL-terminated string with the version
information. This may include not just MAJOR.MINOR.PATCH but possibly also additional
build or development version information.

The returned pointer is to static memory and must not be used to change the contents of
the version string. Multiple calls to the function will return the same address.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_library end

Base.@ccallable function trixi_version_library()::Cstring
    return pointer(_version_libtrixi)
end

trixi_version_library_cfptr() = @cfunction(trixi_version_library, Cstring, ())


"""
    trixi_version_julia()::Cstring

Return name and version of loaded Julia packages LibTrixi directly depends on.

The return value is a read-only pointer to a NULL-terminated string with the name and
version information of the loaded Julia packages, separated by newlines.

The returned pointer is to static memory and must not be used to change the contents of
the version string. Multiple calls to the function will return the same address.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_julia end

Base.@ccallable function trixi_version_julia()::Cstring
    return pointer(_version_info)
end

trixi_version_julia_cfptr() = @cfunction(trixi_version_julia, Cstring, ())


"""
    trixi_version_julia_extended()::Cstring

Return name and version of all loaded Julia packages.

The return value is a read-only pointer to a NULL-terminated string with the name and
version information of all loaded Julia packages, including implicit dependencies,
separated by newlines.

The returned pointer is to static memory and must not be used to change the contents of
the version string. Multiple calls to the function will return the same address.

This function is thread-safe. It must be run after `trixi_initialize` has been called.
"""
function trixi_version_julia_extended end

Base.@ccallable function trixi_version_julia_extended()::Cstring
    return pointer(_version_info_extended)
end

trixi_version_julia_extended_cfptr() = @cfunction(trixi_version_julia_extended, Cstring, ())



############################################################################################
# Simulation control                                                                       #
############################################################################################

"""
    trixi_initialize_simulation(libelixir::Cstring)::Cint
    trixi_initialize_simulation(libelixir::AbstractString)::Cint

Initialize a new simulation based on the file `libelixir`and return a handle to the
corresponding [`SimulationState`](@ref) as a `Cint` (i.e, a plain C `int`).

The libelixir has a similar purpose as a regular "elixir" in Trixi.jl, as it completely
defines a simulation setup in Julia code. A key difference (and thus the name libelixir) is
that instead of running a simulation directly, it should define an argument-less function
named `init_simstate()` that returns a [`SimulationState`](@ref) with the complete
simulation setup. `trixi_initialize_simulation` will store the `SimulationState` object
internally and allow one to use it in subsequent calls to libtrixi via the handle returned
from this function.

For convenience, when using LibTrixi.jl directly from Julia, one can also pass a regular
`String` in the `libelixir` argument.

!!! note "Libelixir hygiene and `init_simstate`"
    The libelixir file will be evaluated in the `Main` module. Thus any previously defined
    function `init_simstate` will be overwritten, and any variables defined outside the
    function will live throughout the lifetime of the Julia process.

!!! warning "Thread safety"
    **This function is not thread safe.** Since the libelixir file will be evaluated in the
    `Main` module, calling `trixi_initialize_simulation` simultaneously from different
    threads can lead to undefined behavior.

"""
function trixi_initialize_simulation end

Base.@ccallable function trixi_initialize_simulation(libelixir::Cstring)::Cint
    # Create string from Cstring
    filename = unsafe_string(libelixir)

    # Create new simulation state and store in global dict
    simstate = trixi_initialize_simulation_jl(filename)
    simstate_handle = store_simstate(simstate)

    # Return handle for usage/storage on C side
    return simstate_handle
end

trixi_initialize_simulation_cfptr() =
    @cfunction(trixi_initialize_simulation, Cint, (Cstring,))


# Convenience function when using this directly from Julia
function trixi_initialize_simulation(libelixir::String)
    # Convert string to byte array
    bytes = Vector{UInt8}(libelixir)

    # Make it a proper, NULL-terminated C-style char array
    push!(bytes, '\0')

    # Call `trixi_initialize_simulation` above with a raw pointer to the bytes array,
    # which needs to be protected from garbage collection
    GC.@preserve bytes begin
        simstate_handle = trixi_initialize_simulation(Cstring(pointer(bytes)))
    end

    return simstate_handle
end


"""
    trixi_is_finished(simstate_handle::Cint)::Cint

Return `0` if the simulation time has not yet reached the final time, and `1` otherwise.
"""
function trixi_is_finished end

Base.@ccallable function trixi_is_finished(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    is_finished = trixi_is_finished_jl(simstate)

    return is_finished ? 1 : 0
end

trixi_is_finished_cfptr() = @cfunction(trixi_is_finished, Cint, (Cint,))


"""
    trixi_step(simstate_handle::Cint)::Cvoid

Advance the simulation in time by one step.
"""
function trixi_step end

Base.@ccallable function trixi_step(simstate_handle::Cint)::Cvoid
    simstate = load_simstate(simstate_handle)
    trixi_step_jl(simstate)

    return nothing
end

trixi_step_cfptr() = @cfunction(trixi_step, Cvoid, (Cint,))


"""
    trixi_finalize_simulation(simstate_handle::Cint)::Cvoid

Finalize a simulation and attempt to free the underlying memory.
"""
function trixi_finalize_simulation end

Base.@ccallable function trixi_finalize_simulation(simstate_handle::Cint)::Cvoid
    # Load simulation state and call finalizer
    simstate = load_simstate(simstate_handle)
    trixi_finalize_simulation_jl(simstate)

    # Remove all references to simulation state and call garbage collection
    simstate = nothing
    delete_simstate!(simstate_handle)
    GC.gc()

    return nothing
end

trixi_finalize_simulation_cfptr() = @cfunction(trixi_finalize_simulation, Cvoid, (Cint,))



############################################################################################
# Simulation data                                                                          #
############################################################################################

"""
    trixi_calculate_dt(simstate_handle::Cint)::Cdouble

Compute, store, and return the time step size for the next time integration step.
"""
function trixi_calculate_dt end

Base.@ccallable function trixi_calculate_dt(simstate_handle::Cint)::Cdouble
    simstate = load_simstate(simstate_handle)
    dt = trixi_calculate_dt_jl(simstate)

    return dt
end

trixi_calculate_dt_cfptr() = @cfunction(trixi_calculate_dt, Cdouble, (Cint,))


"""
    trixi_ndims(simstate_handle::Cint)::Cint

Return number of spatial dimensions.
"""
function trixi_ndims end

Base.@ccallable function trixi_ndims(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_ndims_jl(simstate)
end

trixi_ndims_cfptr() = @cfunction(trixi_ndims, Cint, (Cint,))


"""
    trixi_nelements(simstate_handle::Cint)::Cint

Return number of elements local to the MPI rank.
"""
function trixi_nelements end

Base.@ccallable function trixi_nelements(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_nelements_jl(simstate)
end

trixi_nelements_cfptr() = @cfunction(trixi_nelements, Cint, (Cint,))


"""
    trixi_nelementsglobal(simstate_handle::Cint)::Cint

Return global number of elements on all MPI ranks.
"""
function trixi_nelementsglobal end

Base.@ccallable function trixi_nelementsglobal(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_nelementsglobal_jl(simstate)
end

trixi_nelementsglobal_cfptr() = @cfunction(trixi_nelementsglobal, Cint, (Cint,))


"""
    trixi_ndofs(simstate_handle::Cint)::Cint

Return number of degrees of freedom (all quadrature points on all elements of current rank).
"""
function trixi_ndofs end

Base.@ccallable function trixi_ndofs(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_ndofs_jl(simstate)
end

trixi_ndofs_cfptr() = @cfunction(trixi_ndofs, Cint, (Cint,))


"""
    trixi_ndofsglobal(simstate_handle::Cint)::Cint

Return global number of degrees of freedom (all quadrature points on all elements on all ranks).
"""
function trixi_ndofsglobal end

Base.@ccallable function trixi_ndofsglobal(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_ndofsglobal_jl(simstate)
end

trixi_ndofsglobal_cfptr() = @cfunction(trixi_ndofsglobal, Cint, (Cint,))


"""
    trixi_ndofselement(simstate_handle::Cint)::Cint

Return number of degrees of freedom per element.
"""
function trixi_ndofselement end

Base.@ccallable function trixi_ndofselement(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_ndofselement_jl(simstate)
end

trixi_ndofselement_cfptr() = @cfunction(trixi_ndofselement, Cint, (Cint,))


"""
    trixi_nvariables(simstate_handle::Cint)::Cint

Return number of variables.
"""
function trixi_nvariables end

Base.@ccallable function trixi_nvariables(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_nvariables_jl(simstate)
end

trixi_nvariables_cfptr() = @cfunction(trixi_nvariables, Cint, (Cint,))


"""
    trixi_nnodes(simstate_handle::Cint)::Cint

Return number of quadrature nodes per dimension.
"""
function trixi_nnodes end

Base.@ccallable function trixi_nnodes(simstate_handle::Cint)::Cint
    simstate = load_simstate(simstate_handle)
    return trixi_nnodes_jl(simstate)
end

trixi_nnodes_cfptr() = @cfunction(trixi_nnodes, Cint, (Cint,))


"""
    trixi_load_node_reference_coordinates(simstate_handle::Cint, data::Ptr{Cdouble})::Cvoid

Get reference coordinates of 1D quadrature nodes.
"""
function trixi_load_node_reference_coordinates end

Base.@ccallable function trixi_load_node_reference_coordinates(simstate_handle::Cint,
                                                               data::Ptr{Cdouble})::Cvoid
    simstate = load_simstate(simstate_handle)

    # convert C to Julia array
    size = trixi_nnodes_jl(simstate)
    data_jl = unsafe_wrap(Array, data, size)

    trixi_load_node_reference_coordinates_jl(simstate, data_jl)
    return nothing
end

trixi_load_node_reference_coordinates_cfptr() =
    @cfunction(trixi_load_node_reference_coordinates, Cvoid, (Cint, Ptr{Cdouble}))


"""
    trixi_load_node_weights(simstate_handle::Cint, data::Ptr{Cdouble})::Cvoid

Get weights of 1D quadrature nodes.
"""
function trixi_load_node_weights end

Base.@ccallable function trixi_load_node_weights(simstate_handle::Cint,
                                                 data::Ptr{Cdouble})::Cvoid
    simstate = load_simstate(simstate_handle)

    # convert C to Julia array
    size = trixi_nnodes_jl(simstate)
    data_jl = unsafe_wrap(Array, data, size)

    return trixi_load_node_weights_jl(simstate, data_jl)
end

trixi_load_node_weights_cfptr() =
    @cfunction(trixi_load_node_weights, Cvoid, (Cint, Ptr{Cdouble}))


"""
    trixi_load_primitive_vars(simstate_handle::Cint, variable_id::Cint,
                              data::Ptr{Cdouble})::Cvoid

Load primitive variable.

The values for the primitive variable at position `variable_id` at every degree of freedom
are stored in the given array `data`.

The given array has to be of correct size (ndofs) and memory has to be allocated beforehand.
"""
function trixi_load_primitive_vars end

Base.@ccallable function trixi_load_primitive_vars(simstate_handle::Cint, variable_id::Cint,
                                                   data::Ptr{Cdouble})::Cvoid
    simstate = load_simstate(simstate_handle)

    # convert C to Julia array
    size = trixi_ndofs_jl(simstate)
    data_jl = unsafe_wrap(Array, data, size)

    trixi_load_primitive_vars_jl(simstate, variable_id, data_jl)
    return nothing
end

trixi_load_primitive_vars_cfptr() =
    @cfunction(trixi_load_primitive_vars, Cvoid, (Cint, Cint, Ptr{Cdouble}))


"""
    trixi_register_data(data::Ptr{Cdouble}, size::Cint, index::Cint,
                        simstate_handle::Cint)::Cvoid

Store data vector in current simulation's registry.

A reference to the passed data array `data` will be stored in the registry of the simulation
given by `simstate_handle` at given `index`. The registry object has to be created in
`init_simstate()` of the running libelixir and can be used throughout the simulation.

The registry object has to exist, has to be of type `LibTrixiDataRegistry`, and has to hold
enough data references such that access at `index` is valid.
Memory storage remains on the user side. It must not be deallocated as long as it might be
accessed via the registry. The size of `data` has to match `size`.
"""
function trixi_register_data end

Base.@ccallable function trixi_register_data(simstate_handle::Cint, index::Cint,
                                             size::Cint, data::Ptr{Cdouble})::Cvoid
    simstate = load_simstate(simstate_handle)

    # convert C to Julia array
    data_jl = unsafe_wrap(Array, data, size)

    trixi_register_data_jl(simstate, index, data_jl)
    return nothing
end

trixi_register_data_cfptr() =
    @cfunction(trixi_register_data, Cvoid, (Cint, Cint, Cint, Ptr{Cdouble},))


"""
    trixi_get_simulation_time(simstate_handle::Cint)::Cdouble

Return current physical time.
"""
function trixi_get_simulation_time end

Base.@ccallable function trixi_get_simulation_time(simstate_handle::Cint)::Cdouble
    simstate = load_simstate(simstate_handle)
    return trixi_get_simulation_time_jl(simstate)
end

trixi_get_simulation_time_cfptr() = @cfunction(trixi_get_simulation_time, Cdouble, (Cint,))


"""
    trixi_load_element_averaged_primitive_vars(simstate_handle::Cint, variable_id::Cint,
                                            data::Ptr{Cdouble})::Cvoid

Load element averages for primitive variable.

Element averaged values for the primitive variable at position `variable_id` for each
element are stored in the given array `data`.

The given array has to be of correct size (nelements) and memory has to be allocated
beforehand.
"""
function trixi_load_element_averaged_primitive_vars end

Base.@ccallable function trixi_load_element_averaged_primitive_vars(simstate_handle::Cint,
    variable_id::Cint, data::Ptr{Cdouble})::Cvoid
    simstate = load_simstate(simstate_handle)

    # convert C to Julia array
    size = trixi_nelements_jl(simstate)
    data_jl = unsafe_wrap(Array, data, size)

    trixi_load_element_averaged_primitive_vars_jl(simstate, variable_id, data_jl)
    return nothing
end

trixi_load_element_averaged_primitive_vars_cfptr() =
    @cfunction(trixi_load_element_averaged_primitive_vars, Cvoid, (Cint, Cint, Ptr{Cdouble}))


"""
    trixi_get_data_pointer(simstate_handle::Cint)::Ptr{Cdouble}

Return pointer to internal data vector.
"""
function trixi_get_data_pointer end

Base.@ccallable function trixi_get_data_pointer(simstate_handle::Cint)::Ptr{Cdouble}
    simstate = load_simstate(simstate_handle)
    return trixi_get_data_pointer_jl(simstate)
end

trixi_get_data_pointer_cfptr() = @cfunction(trixi_get_data_pointer, Ptr{Cdouble}, (Cint,))



############################################################################################
# t8code
############################################################################################
"""
    trixi_get_t8code_forest(simstate_handle::Cint)::Ptr{Trixi.t8_forest}

Return t8code forest of the current T8codeMesh.

!!! warning "Experimental"
    The interface to t8code is experimental and implementation details may change at any
    time without warning.
"""
function trixi_get_t8code_forest end

Base.@ccallable function trixi_get_t8code_forest(simstate_handle::Cint)::Ptr{Trixi.t8_forest}
    simstate = load_simstate(simstate_handle)
    return trixi_get_t8code_forest_jl(simstate)
end

trixi_get_t8code_forest_cfptr() =
    @cfunction(trixi_get_t8code_forest, Ptr{Trixi.t8_forest}, (Cint,))



############################################################################################
# Auxiliary
############################################################################################
"""
    trixi_eval_julia(code::Cstring)::Cvoid

Execute the provided code in the current Julia runtime environment.

!!! warning "Only for development"
    Code is not checked prior to execution.
"""
function trixi_eval_julia end

Base.@ccallable function trixi_eval_julia(code::Cstring)::Cvoid
    trixi_eval_julia_jl(unsafe_string(code))
    return # Return nothing to not pass arbitrary Julia objects to C
end

trixi_eval_julia_cfptr() = @cfunction(trixi_eval_julia, Cvoid, (Cstring,))
