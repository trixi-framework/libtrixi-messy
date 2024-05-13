#include "trixi.h"
#include "auxiliary.h"

/******************************************************************************************/
/* Function pointers                                                                      */
/******************************************************************************************/

// Enum to index function pointer array
enum {
    TRIXI_FTPR_INITIALIZE_SIMULATION,
    TRIXI_FTPR_CALCULATE_DT,
    TRIXI_FTPR_IS_FINISHED,
    TRIXI_FTPR_STEP,
    TRIXI_FTPR_FINALIZE_SIMULATION,
    TRIXI_FTPR_NDIMS,
    TRIXI_FPTR_NELEMENTS,
    TRIXI_FPTR_NELEMENTS_GLOBAL,
    TRIXI_FPTR_NDOFS,
    TRIXI_FPTR_NDOFS_GLOBAL,
    TRIXI_FPTR_NDOFS_ELEMENT,
    TRIXI_FTPR_NVARIABLES,
    TRIXI_FTPR_LOAD_CELL_AVERAGES,
    TRIXI_FTPR_LOAD_PRIM,
    TRIXI_FTPR_STORE_IN_DATABASE,
    TRIXI_FTPR_VERSION_LIBRARY,
    TRIXI_FTPR_VERSION_LIBRARY_MAJOR,
    TRIXI_FTPR_VERSION_LIBRARY_MINOR,
    TRIXI_FTPR_VERSION_LIBRARY_PATCH,
    TRIXI_FTPR_VERSION_JULIA,
    TRIXI_FTPR_VERSION_JULIA_EXTENDED,
    TRIXI_FTPR_EVAL_JULIA,
    TRIXI_FTPR_GET_T8CODE_FOREST,
    TRIXI_FPTR_GET_TIME,
    TRIXI_FPTR_LOAD_NODE_COORDINATES,

    // The last one is for the array size
    TRIXI_NUM_FPTRS
};

// Function pointer array
static void* trixi_function_pointers[TRIXI_NUM_FPTRS];

// List of function names to obtain C function pointers from Julia
// OBS! If any name is longer than 250 characters, adjust buffer sizes in setup.c
static const char* trixi_function_pointer_names[] = {
    [TRIXI_FTPR_INITIALIZE_SIMULATION]  = "trixi_initialize_simulation_cfptr",
    [TRIXI_FTPR_CALCULATE_DT]           = "trixi_calculate_dt_cfptr",
    [TRIXI_FTPR_IS_FINISHED]            = "trixi_is_finished_cfptr",
    [TRIXI_FTPR_STEP]                   = "trixi_step_cfptr",
    [TRIXI_FTPR_FINALIZE_SIMULATION]    = "trixi_finalize_simulation_cfptr",
    [TRIXI_FTPR_NDIMS]                  = "trixi_ndims_cfptr",
    [TRIXI_FPTR_NELEMENTS]              = "trixi_nelements_cfptr",
    [TRIXI_FPTR_NELEMENTS_GLOBAL]       = "trixi_nelements_global_cfptr",
    [TRIXI_FPTR_NDOFS]                  = "trixi_ndofs_cfptr",
    [TRIXI_FPTR_NDOFS_GLOBAL]           = "trixi_ndofs_global_cfptr",
    [TRIXI_FPTR_NDOFS_ELEMENT]          = "trixi_ndofs_element_cfptr",
    [TRIXI_FTPR_NVARIABLES]             = "trixi_nvariables_cfptr",
    [TRIXI_FTPR_LOAD_CELL_AVERAGES]     = "trixi_load_cell_averages_cfptr",
    [TRIXI_FTPR_LOAD_PRIM]              = "trixi_load_prim_cfptr",
    [TRIXI_FTPR_STORE_IN_DATABASE]      = "trixi_store_in_database_cfptr",
    [TRIXI_FTPR_VERSION_LIBRARY]        = "trixi_version_library_cfptr",
    [TRIXI_FTPR_VERSION_LIBRARY_MAJOR]  = "trixi_version_library_major_cfptr",
    [TRIXI_FTPR_VERSION_LIBRARY_MINOR]  = "trixi_version_library_minor_cfptr",
    [TRIXI_FTPR_VERSION_LIBRARY_PATCH]  = "trixi_version_library_patch_cfptr",
    [TRIXI_FTPR_VERSION_JULIA]          = "trixi_version_julia_cfptr",
    [TRIXI_FTPR_VERSION_JULIA_EXTENDED] = "trixi_version_julia_extended_cfptr",
    [TRIXI_FTPR_EVAL_JULIA]             = "trixi_eval_julia_cfptr",
    [TRIXI_FTPR_GET_T8CODE_FOREST]      = "trixi_get_t8code_forest_cfptr",
    [TRIXI_FPTR_GET_TIME]               = "trixi_get_time_cfptr",
    [TRIXI_FPTR_LOAD_NODE_COORDINATES]  = "trixi_load_node_coordinates_cfptr"
};

// Track initialization/finalization status to prevent unhelpful errors
static int is_initialized = 0;
static int is_finalized = 0;



/******************************************************************************************/
/* Setup                                                                                  */
/******************************************************************************************/

/**
 * @anchor trixi_initialize_api_c
 *
 * @brief Initialize Julia runtime environment
 * 
 * Initialize Julia and activate the project at `project_directory`. If `depot_path` is not
 * a null pointer, forcefully set the environment variable `JULIA_DEPOT_PATH` to the value
 * of `depot_path`. If `depot_path` *is* null, then proceed as follows:
 * If `JULIA_DEPOT_PATH` is already set, do not touch it. Otherwise, set `JULIA_DEPOT_PATH`
 * to `project_directory` + `default_depot_path`
 * 
 * This function must be called before most other libtrixi functions can be used.
 * Libtrixi maybe only be initialized once; subsequent calls to `trixi_initialize` are
 * erroneous.
 * 
 * @param[in]  project_directory  Path to project directory.
 * @param[in]  depot_path         Path to Julia depot path (optional; can be null pointer).
 */
void trixi_initialize(const char * project_directory, const char * depot_path) {
    // Prevent double initialization
    if (is_initialized) {
        print_and_die("trixi_initialize invoked multiple times", LOC);
    }
    // Initialization after finalization is also erroneous, but finalization requires
    // initialization, so this is already caught above.

    // Update JULIA_DEPOT_PATH environment variable before initializing Julia
    update_depot_path(project_directory, depot_path);

    // Init Julia
    jl_init();

    // Construct activation command
    const char * activate = "using Pkg;\n"
                            "Pkg.activate(\"%s\"; io=devnull);\n";
    if ( strlen(activate) + strlen(project_directory) + 1 > 1024 ) {
        print_and_die("buffer size not sufficient for activation command", LOC);
    }
    char buffer[1024];
    snprintf(buffer, 1024, activate, project_directory);

    // Activate Julia environment
    checked_eval_string(buffer, LOC);

    // Load LibTrixi module
    checked_eval_string("using LibTrixi;", LOC);
    if (show_debug_output()) {
        checked_eval_string("println(\"Module LibTrixi.jl loaded\")", LOC);
    }

    // Store function pointers to avoid overhead of `jl_eval_string`
    store_function_pointers(TRIXI_NUM_FPTRS, trixi_function_pointer_names,
                            trixi_function_pointers);

    // Show version info
    if (show_debug_output()) {
        printf("\nlibtrixi %s\n\n", trixi_version_library());
        printf("Loaded Julia packages:\n%s\n\n", trixi_version_julia());
    }

    // Mark as initialized
    is_initialized = 1;
}


/**
 * @anchor trixi_finalize_api_c
 * 
 * Clean up internal states. This function should be executed near the end of the process'
 * lifetime. After the call to `trixi_finalize`, no other libtrixi functions may be called
 * anymore, including `trixi_finalize` itself.
 *
 * @brief Finalize Julia runtime environment
 */
void trixi_finalize() {
    // Prevent finalization without initialization and double finalization
    if (!is_initialized) {
        print_and_die("trixi_initialize must be called before trixi_finalize", LOC);
    }
    if (is_finalized) {
        print_and_die("trixi_finalize invoked multiple times", LOC);
    }

    if (show_debug_output()) {
        printf("libtrixi: finalize\n");
    }

    // Reset function pointers
    for (int i = 0; i < TRIXI_NUM_FPTRS; i++) {
        trixi_function_pointers[i] = NULL;
    }

    jl_atexit_hook(0);

    // Mark as finalized
    is_finalized = 1;
}



/******************************************************************************************/
/* Version information                                                                    */
/******************************************************************************************/

/**
 * @anchor trixi_version_library_major_api_c
 *
 * @brief Return major version number of libtrixi.
 *
 * This function may be run before `trixi_initialize` has been called.
 *
 * @return Major version of libtrixi.
 */
int trixi_version_library_major() {

    // Get function pointer
    int (*version_library_major)() =
        trixi_function_pointers[TRIXI_FTPR_VERSION_LIBRARY_MAJOR];

    // Call function
    return version_library_major();
}


/**
 * @anchor trixi_version_library_minor_api_c
 *
 * @brief Return minor version number of libtrixi.
 *
 * This function may be run before `trixi_initialize` has been called.
 *
 * @return Minor version of libtrixi.
 */
int trixi_version_library_minor() {

    // Get function pointer
    int (*version_library_minor)() =
        trixi_function_pointers[TRIXI_FTPR_VERSION_LIBRARY_MINOR];

    // Call function
    return version_library_minor();
}


/**
 * @anchor trixi_version_library_patch_api_c
 *
 * @brief Return patch version number of libtrixi.
 *
 * This function may be run before `trixi_initialize` has been called.
 *
 * @return Patch version of libtrixi.
 */
int trixi_version_library_patch() {

    // Get function pointer
    int (*version_library_patch)() =
        trixi_function_pointers[TRIXI_FTPR_VERSION_LIBRARY_PATCH];

    // Call function
    return version_library_patch();
}


/**
 * @anchor trixi_version_library_api_c
 *
 * @brief Return full version string of libtrixi.
 *
 * The return value is a read-only pointer to a NULL-terminated string with the version
 * information. This may include not just MAJOR.MINOR.PATCH but possibly also additional
 * build or development version information.
 *
 * The returned pointer is to static memory and must not be used to change the contents of
 * the version string. Multiple calls to the function will return the same address.
 *
 * This function is thread-safe and may be run before `trixi_initialize` has been called.
 *
 * @return Pointer to a read-only, NULL-terminated character array with the full version of
 *         libtrixi.
 */
const char* trixi_version_library() {

    // Get function pointer
    const char* (*version_library)() = trixi_function_pointers[TRIXI_FTPR_VERSION_LIBRARY];

    // Call function
    return version_library();
}


/**
 * @anchor trixi_version_julia_api_c
 *
 * @brief Return name and version of loaded Julia packages LibTrixi directly depends on.
 *
 * The return value is a read-only pointer to a NULL-terminated string with the name and
 * version information of the loaded Julia packages, separated by newlines.
 *
 * The returned pointer is to static memory and must not be used to change the contents of
 * the version string. Multiple calls to the function will return the same address.
 *
 * This function is thread-safe. It must be run after `trixi_initialize` has been called.
 *
 * @return Pointer to a read-only, NULL-terminated character array with the names and
 *         versions of loaded Julia packages.
 */
const char* trixi_version_julia() {

    // Get function pointer
    const char* (*version_julia)() = trixi_function_pointers[TRIXI_FTPR_VERSION_JULIA];

    // Call function
    return version_julia();
}


/**
 * @anchor trixi_version_julia_extended_api_c
 *
 * @brief Return name and version of all loaded Julia packages.
 *
 * The return value is a read-only pointer to a NULL-terminated string with the name and
 * version information of all loaded Julia packages, including implicit dependencies,
 * separated by newlines.
 *
 * The returned pointer is to static memory and must not be used to change the contents of
 * the version string. Multiple calls to the function will return the same address.
 *
 * This function is thread-safe. It must be run after `trixi_initialize` has been called.
 *
 * @return Pointer to a read-only, NULL-terminated character array with the names and
 *         versions of all loaded Julia packages.
 */
const char* trixi_version_julia_extended() {

    // Get function pointer
    const char* (*version_julia_extended)() =
        trixi_function_pointers[TRIXI_FTPR_VERSION_JULIA_EXTENDED];

    // Call function
    return version_julia_extended();
}



/******************************************************************************************/
/* Simulation control                                                                     */
/******************************************************************************************/

/**
 * @anchor trixi_initialize_simulation_api_c
 *
 * @brief Set up Trixi simulation
 *
 * Set up a Trixi simulation by reading the provided libelixir file. It resembles Trixi's
 * typical elixir files with the following differences:
 * - Everything (except `using ...`) has to be inside a `function init_simstate()`
 * - OrdinaryDiffEq's integrator has to be created by calling `init` (instead of `solve`)
 * - A `SimulationState` has to be created from the semidiscretization and the integrator
 * See the examples in the `LibTrixi.jl/examples` folder
 *
 * @param[in]  libelixir  Path to libelexir file.
 *
 * @return handle (integer) to Trixi simulation instance
 */
int trixi_initialize_simulation(const char * libelixir) {

    // Get function pointer
    int (*initialize_simulation)(const char *) =
        trixi_function_pointers[TRIXI_FTPR_INITIALIZE_SIMULATION];

    // Call function
    return initialize_simulation( libelixir );
}


/**
 * @anchor trixi_is_finished_api_c
 *
 * @brief Check if simulation is finished
 *
 * Checks if the simulation identified by handle has reached its final time.
 *
 * @param[in]  handle  simulation handle
 *
 * @return 1 if finished, 0 if not
 */
int trixi_is_finished(int handle) {

    // Get function pointer
    int (*is_finished)(int) = trixi_function_pointers[TRIXI_FTPR_IS_FINISHED];

    // Call function
    return is_finished( handle );
}


/**
 * @anchor trixi_step_api_c
 *
 * @brief Perform next simulation step
 *
 * Let the simulation identified by handle advance by one step.
 *
 * @param[in]  handle  simulation handle
 */
void trixi_step(int handle) {

    // Get function pointer
    int (*step)(int) = trixi_function_pointers[TRIXI_FTPR_STEP];

    // Call function
    step( handle );
}


/**
 * @anchor trixi_finalize_simulation_api_c
 *
 * @brief Finalize simulation
 *
 * Finalize the simulation identified by handle. This will also release the handle.
 *
 * @param[in]  handle  simulation handle
 */
void trixi_finalize_simulation(int handle) {

    // Get function pointer
    void (*finalize_simulation)(int) =
        trixi_function_pointers[TRIXI_FTPR_FINALIZE_SIMULATION];

    // Call function
    finalize_simulation(handle);
}



/******************************************************************************************/
/* Simulation data                                                                        */
/******************************************************************************************/

/**
 * @anchor trixi_calculate_dt_api_c
 *
 * @brief Get time step length
 *
 * Get the current time step length of the simulation identified by handle.
 *
 * @param[in]  handle  simulation handle
 *
 * @return Time step length
 */
double trixi_calculate_dt(int handle) {

    // Get function pointer
    double (*calculate_dt)(int) = trixi_function_pointers[TRIXI_FTPR_CALCULATE_DT];;

    // Call function
    return calculate_dt( handle );
}


/**
 * @anchor trixi_ndims_api_c
 *
 * @brief Return number of spatial dimensions
 *
 * @param[in]  handle  simulation handle
 */
int trixi_ndims(int handle) {

    // Get function pointer
    int (*ndims)(int) = trixi_function_pointers[TRIXI_FTPR_NDIMS];

    // Call function
    return ndims(handle);
}


/**
 * @anchor trixi_nelements_api_c
 *
 * @brief Return number of local elements (cells).
 *
 * These usually differ from the global count when doing parallel computations.
 *
 * @param[in]  handle  simulation handle
 *
 * @see trixi_nelements_global_api_c
 */
int trixi_nelements(int handle) {

    // Get function pointer
    int (*nelements)(int) = trixi_function_pointers[TRIXI_FPTR_NELEMENTS];

    // Call function
    return nelements(handle);
}


/**
 * @anchor trixi_nelements_global_api_c
 *
 * @brief Return number of global elements (cells).
 *
 * These usually differ from the local count when doing parallel computations.
 *
 * @param[in]  handle  simulation handle
 *
 * @see trixi_nelements_api_c
 */
int trixi_nelements_global(int handle) {

    // Get function pointer
    int (*nelements_global)(int) = trixi_function_pointers[TRIXI_FPTR_NELEMENTS_GLOBAL];

    // Call function
    return nelements_global(handle);
}


/**
 * @anchor trixi_ndofs_api_c
 *
 * @brief Return number of local degrees of freedom.
 *
 * These usually differ from the global count when doing parallel computations.
 *
 * @param[in]  handle  simulation handle
 *
 * @see trixi_ndofs_global_api_c
 */
int trixi_ndofs(int handle) {

    // Get function pointer
    int (*ndofs)(int) = trixi_function_pointers[TRIXI_FPTR_NDOFS];

    // Call function
    return ndofs(handle);
}


/**
 * @anchor trixi_ndofs_global_api_c
 *
 * @brief Return number of global degrees of freedom.
 *
 * These usually differ from the local count when doing parallel computations.
 *
 * @param[in]  handle  simulation handle
 *
 * @see trixi_ndofs_api_c
 */
int trixi_ndofs_global(int handle) {

    // Get function pointer
    int (*ndofs_global)(int) = trixi_function_pointers[TRIXI_FPTR_NDOFS_GLOBAL];

    // Call function
    return ndofs_global(handle);
}


/**
 * @anchor trixi_ndofs_element_api_c
 *
 * @brief Return number of degrees of freedom per element (cell).
 *
 * @param[in]  handle  simulation handle
 */
int trixi_ndofs_element(int handle) {

    // Get function pointer
    int (*ndofs_element)(int) = trixi_function_pointers[TRIXI_FPTR_NDOFS_ELEMENT];

    // Call function
    return ndofs_element(handle);
}


/**
 * @anchor trixi_nvariables_api_c
 *
 * @brief Return number of (conservative) variables
 *
 * @param[in]  handle  simulation handle
 */
int trixi_nvariables(int handle) {

    // Get function pointer
    int (*nvariables)(int) = trixi_function_pointers[TRIXI_FTPR_NVARIABLES];

    // Call function
    return nvariables(handle);
}


/** 
 * @anchor trixi_load_cell_averages_api_c
 *
 * @brief Return cell averaged solution state
 *
 * Cell averaged values for the primitive variable at position index for each cell are
 * stored in the given array `data`.
 *
 * The given array has to be of correct size and memory has to be allocated beforehand.
 *
 * @param[in]  handle  simulation handle
 * @param[in]  index   index of variable
 * @param[out] data    cell averaged values for all cells and all primitive variables
 */
void trixi_load_cell_averages(double * data, int index, int handle) {

    // Get function pointer
    void (*load_cell_averages)(double *, int, int) =
        trixi_function_pointers[TRIXI_FTPR_LOAD_CELL_AVERAGES];

    // Call function
    load_cell_averages(data, index, handle);
}


/**
 * @anchor trixi_load_prim_api_c
 *
 * @brief Return primitive variable
 *
 * The values for the primitive variable at position index at every degree of freedom for
 * the simulation given by simstate_handle is stored in the given array data.
 *
 * The given array has to be of correct size and memory has to be allocated beforehand.
 *
 * @param[in]  handle  simulation handle
 * @param[in]  index   index of variable
 * @param[out] data    cell averaged values for all cells and all primitive variables
 */
void trixi_load_prim(double * data, int index, int handle) {

    // Get function pointer
    void (*load_prim)(double *, int, int) =
        trixi_function_pointers[TRIXI_FTPR_LOAD_PRIM];

    // Call function
    load_prim(data, index, handle);
}


/**
 * @anchor trixi_store_in_database_api_c
 *
 * @brief Store data vector in current simulation's database
 *
 * A reference to the passed data array data will be stored in the database of the
 * simulation given by simstate_handle at given index. The database object has to be
 * created in init_simstate() of the running libelixir and can be used throughout the
 * simulation.
 *
 * The database object has to exist, has to be of type `LibTrixiDataBaseType`, and has to
 * hold enough data references such that access at `index` is valid.
 *
 * The size of data has to match size.
 *
 * @param[in]  handle  simulation handle
 * @param[in]  index   index in database where data vector will be stored
 * @param[in]  size    size of given data vector
 * @param[in]  data    data vector to store
 */
void trixi_store_in_database(int handle, int index, int size, const double * data) {

    // Get function pointer
    void (*store_in_database)(int, int, int, const double *) =
        trixi_function_pointers[TRIXI_FTPR_STORE_IN_DATABASE];

    // Call function
    store_in_database(handle, index, size, data);
}


/**
 * @anchor trixi_get_time_api_c
 *
 * @brief Return current physical time.
 *
 * @param[in]  handle  simulation handle
 *
 * @return physical time
 */
double trixi_get_time(int handle) {

    // Get function pointer
    double (*get_time)(int) = trixi_function_pointers[TRIXI_FPTR_GET_TIME];

    // Call function
    return get_time(handle);
}


/**
 * @anchor trixi_load_node_coordinates_api_c
 *
 * @brief Get coordinates of all nodes (degrees of freedom).
 *
 * The coordinates of all nodes (degress of freedom in the DG method) are stored dimension-
 * wise in the provided array `x`, i.e. x-coordinates will be in the beginning and so on.
 * The given array has to be of correct size, i.e. number of nodes times dimension, and
 * memory has to be allocated beforehand.
 *
 * @param[in]   handle  simulation handle
 * @param[out]  x       node coordinates
 */
void trixi_load_node_coordinates(int handle, double* x) {

    // Get function pointer
    void (*load_node_coordinates)(int, double*) = trixi_function_pointers[TRIXI_FPTR_LOAD_NODE_COORDINATES];

    // Call function
    return load_node_coordinates(handle, x);
}



/******************************************************************************************/
/* T8code                                                                                 */
/******************************************************************************************/

/** Get t8code forest
 *
 *  For Trixi simulations on t8code meshes, the t8code forest is returned.
 *
 *  \param[in] handle simulation handle
 *
 *  \warning The interface to t8code is experimental and implementation details may change
 *           at any time without warning.
 *
 *  \return t8code forest
 */
t8_forest_t trixi_get_t8code_forest(int handle) {

    // Get function pointer
    t8_forest_t (*get_t8code_forest)(int) =
        trixi_function_pointers[TRIXI_FTPR_GET_T8CODE_FOREST];

    // Call function
    return get_t8code_forest(handle);
}



/******************************************************************************************/
/* Misc                                                                                   */
/******************************************************************************************/

/**
 * @anchor trixi_eval_julia_api_c
 *
 * @brief Execute Julia code
 *
 * Execute the provided code in the current Julia runtime environment.
 *
 * @warning Only for development. Code is not checked prior to execution.
 */
void trixi_eval_julia(const char * code) {

    // Get function pointer
    void (*eval_julia)(const char *) = trixi_function_pointers[TRIXI_FTPR_EVAL_JULIA];

    // Call function
    eval_julia(code);
}
