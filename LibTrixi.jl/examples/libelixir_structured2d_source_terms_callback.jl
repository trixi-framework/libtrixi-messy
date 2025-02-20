using LibTrixi
using Trixi
using OrdinaryDiffEq
using Libdl

# TODO: hard-coded path for SO
so_handle = dlopen("./lib/libsource_terms.so")
println("Opened library ", dlpath(so_handle))
source_term_fptr = dlsym(so_handle, "source_term_wave")
println("Obtained function pointer ", source_term_fptr)

# TODO: global buffer to avoid allocation of temporary storage in source_term_callback
sources_tmp::Vector{Cdouble} = Vector{Cdouble}(undef, 4)

function source_term_callback(u, x, t, equations::CompressibleEulerEquations2D)
    @ccall $source_term_fptr(u::Ptr{Cdouble}, x::Ptr{Cdouble}, t::Cdouble,
                                      equations.gamma::Cdouble,
                                      sources_tmp::Ptr{Cdouble})::Cvoid
    return SVector(sources_tmp[1], sources_tmp[2], sources_tmp[3], sources_tmp[4])
end

# The function to create the simulation state needs to be named `init_simstate`
function init_simstate()

    ###############################################################################
    # semidiscretization of the compressible Euler equations

    equations = CompressibleEulerEquations2D(1.4)

    initial_condition = initial_condition_convergence_test

    solver = DGSEM(polydeg = 3, surface_flux = flux_lax_friedrichs)

    coordinates_min = (0.0, 0.0)
    coordinates_max = (2.0, 2.0)

    cells_per_dimension = (16, 16)

    mesh = StructuredMesh(cells_per_dimension, coordinates_min, coordinates_max)

    semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver,
                                        source_terms = source_term_callback)

    ###############################################################################
    # ODE solvers, callbacks etc.

    tspan = (0.0, 2.0)
    ode = semidiscretize(semi, tspan)

    summary_callback = SummaryCallback()

    analysis_interval = 100
    analysis_callback = AnalysisCallback(semi, interval = analysis_interval)

    alive_callback = AliveCallback(analysis_interval = analysis_interval)

    save_solution = SaveSolutionCallback(interval = 100,
                                        save_initial_solution = true,
                                        save_final_solution = true,
                                        solution_variables = cons2prim)

    stepsize_callback = StepsizeCallback(cfl = 1.0)

    callbacks = CallbackSet(summary_callback,
                            analysis_callback, alive_callback,
                            save_solution,
                            stepsize_callback)

    ###############################################################################
    # create OrdinaryDiffEq's `integrator`

    integrator = init(ode,
                      CarpenterKennedy2N54(williamson_condition=false),
                      dt=1.0, # will be overwritten by the stepsize_callback
                      save_everystep=false,
                      callback=callbacks);

    ###############################################################################
    # Create simulation state

    simstate = SimulationState(semi, integrator)

    return simstate
end
