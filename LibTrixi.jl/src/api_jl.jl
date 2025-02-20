############################################################################################
# Simulation control                                                                       #
############################################################################################

function trixi_initialize_simulation_jl(filename)
    # Load elixir with simulation setup
    Base.include(Main, abspath(filename))

    # Initialize simulation state
    # Note: we need `invokelatest` here since the function is dynamically upon `include`
    # Note: `invokelatest` is not exported until Julia v1.9, thus we call it through `Base`
    simstate = Base.invokelatest(Main.init_simstate)

    if show_debug_output()
        println("Simulation state initialized")
    end

    return simstate
end


function trixi_is_finished_jl(simstate)
    # Return true if current time is approximately the final time
    return isapprox(simstate.integrator.t, simstate.integrator.sol.prob.tspan[2])
end


function trixi_step_jl(simstate)
    step!(simstate.integrator)

    ret = check_error(simstate.integrator)

    if ret != :Success
        error("integrator failed to perform time step, return code: ", ret)
    end

    return nothing
end


function trixi_finalize_simulation_jl(simstate)
    # Run summary callback one final time
    for cb in simstate.integrator.opts.callback.discrete_callbacks
        if cb isa DiscreteCallback{<:Any, typeof(summary_callback)}
            cb()
        end
    end

    # In course of garbage collection, MPI might get finalized before t8code related
    # objects. This can lead to crashes because t8code allocates MPI related objects, e.g.
    # shared memory arrays.
    # T8code.jl implements manual ref counting to deal with this issue.
    # For p4est the workaround is to finalize P4estMeshes explicitly in advance.
    # x-ref: https://github.com/DLR-AMR/t8code/issues/1295
    # x-ref: https://github.com/trixi-framework/libtrixi/pull/215#discussion_r1843676330
    mesh, _, _, _ = mesh_equations_solver_cache(simstate.semi)
    if mesh isa Trixi.P4estMesh
        finalize(mesh)
    end

    if show_debug_output()
        println("Simulation state finalized")
    end

    return nothing
end



############################################################################################
# Simulation data                                                                          #
############################################################################################

function trixi_calculate_dt_jl(simstate)
    return simstate.integrator.dtpropose
end


function trixi_ndims_jl(simstate)
    mesh, _, _, _ = mesh_equations_solver_cache(simstate.semi)
    return ndims(mesh)
end


function trixi_nelements_jl(simstate)
    _, _, solver, cache = mesh_equations_solver_cache(simstate.semi)
    return nelements(solver, cache)
end


function trixi_nelementsglobal_jl(simstate)
    mesh, _, solver, cache = mesh_equations_solver_cache(simstate.semi)
    return nelementsglobal(mesh, solver, cache)
end


function trixi_ndofs_jl(simstate)
    mesh, _, solver, cache = mesh_equations_solver_cache(simstate.semi)
    return ndofs(mesh, solver, cache)
end


function trixi_ndofsglobal_jl(simstate)
    mesh, _, solver, cache = mesh_equations_solver_cache(simstate.semi)
    return ndofsglobal(mesh, solver, cache)
end


function trixi_ndofselement_jl(simstate)
    mesh, _, solver, _ = mesh_equations_solver_cache(simstate.semi)
    return nnodes(solver)^ndims(mesh)
end


function trixi_nvariables_jl(simstate)
    _, equations, _, _ = mesh_equations_solver_cache(simstate.semi)
    return nvariables(equations)
end


function trixi_nnodes_jl(simstate)
    _, _, solver, _ = mesh_equations_solver_cache(simstate.semi)
    return nnodes(solver)
end


function trixi_load_node_reference_coordinates_jl(simstate, data)
    _, _, solver, _ = mesh_equations_solver_cache(simstate.semi)
    for i in eachnode(solver)
        data[i] = solver.basis.nodes[i]
    end
end


function trixi_load_node_weights_jl(simstate, data)
    _, _, solver, _ = mesh_equations_solver_cache(simstate.semi)
    for i in eachnode(solver)
        data[i] = solver.basis.weights[i]
    end
end


function trixi_load_primitive_vars_jl(simstate, variable_id, data)
    mesh, equations, solver, cache = mesh_equations_solver_cache(simstate.semi)
    n_nodes_per_dim = nnodes(solver)
    n_dims = ndims(mesh)
    n_nodes = n_nodes_per_dim^n_dims

    u_ode = simstate.integrator.u
    u = wrap_array(u_ode, mesh, equations, solver, cache)

    # all permutations of nodes indices for arbitrary dimension
    node_cis = CartesianIndices(ntuple(i -> n_nodes_per_dim, n_dims))
    node_lis = LinearIndices(node_cis)

    for element in eachelement(solver, cache)
        for node_ci in node_cis
            node_vars = get_node_vars(u, equations, solver, node_ci, element)
            node_index = (element-1) * n_nodes + node_lis[node_ci]
            data[node_index] = cons2prim(node_vars, equations)[variable_id]
        end
    end

    return nothing
end


function trixi_load_element_averaged_primitive_vars_jl(simstate, variable_id, data)
    mesh, equations, solver, cache = mesh_equations_solver_cache(simstate.semi)
    n_nodes = nnodes(solver)
    n_dims = ndims(mesh)

    u_ode = simstate.integrator.u
    u = wrap_array(u_ode, mesh, equations, solver, cache)

    # all permutations of nodes indices for arbitrary dimension
    node_cis = CartesianIndices(ntuple(i -> n_nodes, n_dims))

    for element in eachelement(solver, cache)

        # compute mean value using nodal dg values and quadrature
        u_mean = zero(eltype(u))
        for node_ci in node_cis
            u_node_prim = cons2prim(get_node_vars(u, equations, solver, node_ci, element),
                                    equations)[variable_id]
            weight = 1.
            for node_index in Tuple(node_ci)
                weight *= solver.basis.weights[node_index]
            end
            u_mean += u_node_prim * weight
        end

        # normalize to unit element
        u_mean = u_mean / 2^n_dims

        # write to provided array
        data[element] = u_mean
    end

    return nothing
end


function trixi_register_data_jl(simstate, index, data)
    simstate.registry[index] = data
    if show_debug_output()
        println("New data vector registered at index ", index)
    end
    return nothing
end


function trixi_get_simulation_time_jl(simstate)
    return simstate.integrator.t
end


function trixi_get_t8code_forest_jl(simstate)
    mesh, _, _, _ = mesh_equations_solver_cache(simstate.semi)
    return mesh.forest.pointer
end


function trixi_get_p4est_mesh_jl(simstate)
    mesh, _, _, _ = Trixi.mesh_equations_solver_cache(simstate.semi)
    return mesh.p4est
end


function trixi_get_p8est_mesh_jl(simstate)
    mesh, _, _, _ = Trixi.mesh_equations_solver_cache(simstate.semi)
    return mesh.p8est
end

############################################################################################
# Auxiliary
############################################################################################
function trixi_eval_julia_jl(code)
    expr = Meta.parse(code)
    return Base.eval(Main, expr)
end
