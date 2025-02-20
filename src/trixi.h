#ifndef TRIXI_H_
#define TRIXI_H_

/**
 * @addtogroup api_c C API
 * @{
*/

// Setup
void trixi_initialize(const char * project_directory, const char * depot_path);
void trixi_finalize();

// Version information
int trixi_version_library_major();
int trixi_version_library_minor();
int trixi_version_library_patch();
const char* trixi_version_library();
const char* trixi_version_julia();
const char* trixi_version_julia_extended();

// Simulation control
int trixi_initialize_simulation(const char * libelixir);
void trixi_finalize_simulation(int handle);
int trixi_is_finished(int handle);
void trixi_step(int handle);

// Simulation data
int trixi_ndims(int handle);
int trixi_nelements(int handle);
int trixi_nelementsglobal(int handle);
int trixi_ndofs(int handle);
int trixi_ndofsglobal(int handle);
int trixi_ndofselement(int handle);
int trixi_nvariables(int handle);
int trixi_nnodes(int handle);
double trixi_calculate_dt(int handle);
double trixi_get_simulation_time(int handle);
void trixi_load_node_reference_coordinates(int handle, double* node_coords);
void trixi_load_node_weights(int handle, double* node_weights);
void trixi_load_primitive_vars(int handle, int variable_id, double * data);
void trixi_load_element_averaged_primitive_vars(int handle, int variable_id, double * data);
void trixi_register_data(int handle, int index, int size, const double * data);
double * trixi_get_data_pointer(int handle);

// T8code
#if !defined(T8_H) && !defined(T8_FOREST_GENERAL_H)
typedef struct t8_forest *t8_forest_t;
#endif
t8_forest_t trixi_get_t8code_forest(int handle);

// Misc
void trixi_eval_julia(const char * code);

/**
 * @}
 */

#endif // ifndef LIBTRIXI_H_
