!>
!! @addtogroup api_f Fortran API
!!
!! **NOTE**: It is a known limitation of doxygen that Fortran interfaces will be listed as
!! "Data Types". Please refer to the "Functions/Subroutines" section instead.
!!
!! @{

module LibTrixi
  implicit none

  interface
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! Setup                                                                              !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !>
    !! @fn LibTrixi::trixi_initialize_c::trixi_initialize_c(project_directory, depot_path)
    !!
    !! @brief Initialize Julia runtime environment (C char pointer version)
    !!
    !! Initialize Julia and activate the project at `project_directory`. If `depot_path` is
    !! given, forcefully set the environment variable `JULIA_DEPOT_PATH` to the value of
    !! depot_path`. If `depot_path` is not given, then proceed as follows: If
    !! `JULIA_DEPOT_PATH` is already set, do not touch it. Otherwise, set
    !! `JULIA_DEPOT_PATH` to `project_directory` + `default_depot_path`.
    !!
    !! This routine must be called before most other libtrixi routines can be used.
    !! Libtrixi maybe only be initialized once; subsequent calls to `trixi_initialize` are
    !! erroneous.
    !!
    !! @param[in]  project_directory  Path to project directory (C char pointer)
    !! @param[in]  depot_path         Path to Julia depot path (optional, C char pointer)
    !!
    !! @see @ref trixi_initialize        "trixi_initialize (Fortran convenience version)"
    !! @see @ref trixi_initialize_api_c  "trixi_initialize (C API)"
    subroutine trixi_initialize_c(project_directory, depot_path) bind(c, name='trixi_initialize')
      use, intrinsic :: iso_c_binding, only: c_char
      character(kind=c_char), dimension(*), intent(in) :: project_directory
      character(kind=c_char), dimension(*), intent(in), optional :: depot_path
    end subroutine

    !>
    !! @fn LibTrixi::trixi_finalize::trixi_finalize()
    !!
    !! @brief Finalize Julia runtime environment.
    !!
    !! Clean up internal states. This routine should be executed near the end of the
    !! process' lifetime. After the call to `trixi_finalize`, no other libtrixi routines may
    !! be called anymore, including `trixi_finalize` itself.
    !!
    !! @see @ref trixi_finalize_api_c "trixi_finalize (C API)"
    subroutine trixi_finalize() bind(c)
    end subroutine



    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! Version information                                                                !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !>
    !! @fn LibTrixi::trixi_version_library_major::trixi_version_library_major()
    !!
    !! @brief Return major version number of libtrixi.
    !!
    !! @return Major version number as integer.
    !!
    !! @see @ref trixi_version_library_major_api_c "trixi_version_library_major (C API)"
    integer(c_int) function trixi_version_library_major() bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
    end function

    !>
    !! @fn LibTrixi::trixi_version_library_minor::trixi_version_library_minor()
    !!
    !! @brief Return minor version number of libtrixi.
    !!
    !! @return Minor version number as integer.
    !!
    !! @see @ref trixi_version_library_minor_api_c "trixi_version_library_minor (C API)"
    integer(c_int) function trixi_version_library_minor() bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
    end function

    !>
    !! @fn LibTrixi::trixi_version_library_patch::trixi_version_library_patch()
    !!
    !! @brief Return patch version number of libtrixi.
    !!
    !! @return Patch version number as integer.
    !!
    !! @see @ref trixi_version_library_patch_api_c "trixi_version_library_patch (C API)"
    integer(c_int) function trixi_version_library_patch() bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
    end function

    !>
    !! @fn LibTrixi::trixi_version_library_c::trixi_version_library_c()
    !!
    !! @brief Return full version string of libtrixi (C char pointer version).
    !!
    !! @return Full version string as C char pointer.
    !!
    !! @see @ref trixi_version_library
    !!           "trixi_version_library (Fortran convenience version)"
    !! @see @ref trixi_version_library_api_c
    !!           "trixi_version_library (C API)"
    type(c_ptr) function trixi_version_library_c() bind(c, name='trixi_version_library')
      use, intrinsic :: iso_c_binding, only: c_ptr
    end function

    !>
    !! @fn LibTrixi::trixi_version_julia_c::trixi_version_julia_c()
    !!
    !! @brief Return name and version of loaded julia packages LibTrixi directly depends on
    !!        (C char pointer version).
    !!
    !! @return Name and version of loaded julia packages as C char pointer.
    !!
    !! @see @ref trixi_version_julia
    !!           "trixi_version_julia (Fortran convenience version)"
    !! @see @ref trixi_version_julia_api_c
    !!           "trixi_version_julia (C API)"
    type(c_ptr) function trixi_version_julia_c() bind(c, name='trixi_version_julia')
      use, intrinsic :: iso_c_binding, only: c_ptr
    end function

    !>
    !! @fn LibTrixi::trixi_version_julia_extended_c::trixi_version_julia_extended_c()
    !!
    !! @brief Return name and version of all loaded julia packages (C char pointer version).
    !!
    !! @return Name and version of loaded julia packages as C char pointer.
    !!
    !! @see @ref trixi_version_julia_extended
    !!           "trixi_version_julia_extended (Fortran convenience version)"
    !! @see @ref trixi_version_julia_extended_api_c
    !!           "trixi_version_julia_extended (C API)"
    type(c_ptr) function trixi_version_julia_extended_c() &
      bind(c, name='trixi_version_julia_extended')
      use, intrinsic :: iso_c_binding, only: c_ptr
    end function
  


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! Simulation control                                                                 !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !>
    !! @fn LibTrixi::trixi_initialize_simulation_c::trixi_initialize_simulation_c(libelexir)
    !!
    !! @brief Set up Trixi simulation (C char pointer version)
    !!
    !! @param[in]  libelixir  Path to libelexir file.
    !!
    !! @return handle (integer) to Trixi simulation instance
    !!
    !! @see @ref trixi_initialize_simulation
    !!           "trixi_initialize_simulation (Fortran convenience version)"
    !! @see @ref trixi_initialize_simulation_api_c
    !!           "trixi_initialize_simulation (C API)"
    integer(c_int) function trixi_initialize_simulation_c(libelixir) &
      bind(c, name='trixi_initialize_simulation')
      use, intrinsic :: iso_c_binding, only: c_char, c_int
      character(kind=c_char), dimension(*), intent(in) :: libelixir
    end function

    !>
    !! @fn LibTrixi::trixi_is_finished_c::trixi_is_finished_c(handle)
    !!
    !! @brief Check if simulation is finished (C integer version)
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @return 1 if finished, 0 if not
    !!
    !! @see @ref trixi_is_finished
    !!           "trixi_is_finished (Fortran convenience version)"
    !! @see @ref trixi_is_finished_api_c
    !!           "trixi_is_finished (C API)"
    integer(c_int) function trixi_is_finished_c(handle) bind(c, name='trixi_is_finished')
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_step::trixi_step(handle)
    !!
    !! @brief Perform next simulation step
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_step_api_c "trixi_step (C API)"
    subroutine trixi_step(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end subroutine

    !>
    !! @fn LibTrixi::trixi_finalize_simulation::trixi_finalize_simulation(handle)
    !!
    !! @brief Finalize simulation
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see trixi_finalize_simulation_api_c "trixi_finalize_simulation (C API)"
    subroutine trixi_finalize_simulation(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end subroutine



    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! Simulation data                                                                    !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !>
    !! @fn LibTrixi::trixi_calculate_dt::trixi_calculate_dt(handle)
    !!
    !! @brief Get time step length
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @return Time step length
    !!
    !! @see @ref trixi_calculate_dt_api_c "trixi_calculate_dt (C API)"
    real(c_double) function trixi_calculate_dt(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_ndims::trixi_ndims(handle)
    !!
    !! @brief Return number of spatial dimensions
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_ndims_api_c "trixi_ndims (C API)"
    integer(c_int) function trixi_ndims(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_nelements::trixi_nelements(handle)
    !!
    !! @brief Return number of local elements
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_nelements_api_c "trixi_nelements (C API)"
    integer(c_int) function trixi_nelements(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_nelementsglobal::trixi_nelementsglobal(handle)
    !!
    !! @brief Return global number of elements
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_nelementsglobal_api_c "trixi_nelementsglobal (C API)"
    integer(c_int) function trixi_nelementsglobal(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_ndofs::trixi_ndofs(handle)
    !!
    !! @brief Return number of local degrees of freedom
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_ndofs_api_c "trixi_ndofs (C API)"
    integer(c_int) function trixi_ndofs(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_ndofsglobal::trixi_ndofsglobal(handle)
    !!
    !! @brief Return global number of degrees of freedom
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_ndofsglobal_api_c "trixi_ndofsglobal (C API)"
    integer(c_int) function trixi_ndofsglobal(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_ndofselement::trixi_ndofselement(handle)
    !!
    !! @brief Return number of degrees of freedom per element.
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_ndofselement_api_c "trixi_ndofselement (C API)"
    integer(c_int) function trixi_ndofselement(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_nvariables::trixi_nvariables(handle)
    !!
    !! @brief Return number of (conservative) variables
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_nvariables_api_c "trixi_nvariables (C API"
    integer(c_int) function trixi_nvariables(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_nnodes::trixi_nnodes(handle)
    !!
    !! @brief Return number of quadrature nodes per dimension.
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @see @ref trixi_nnodes_api_c "trixi_nnodes (C API)"
    integer(c_int) function trixi_nnodes(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_load_node_reference_coordinates::trixi_load_node_reference_coordinates(handle, node_coords)
    !!
    !! @brief Get reference coordinates of 1D quadrature nodes.
    !!
    !! The reference coordinates in [-1,1] of the quadrature nodes in the current DG scheme are
    !! stored in the provided array `node_coords`. The given array has to be of correct size,
    !! i.e. `nnodes`, and memory has to be allocated beforehand.
    !!
    !! @param[in]   handle       simulation handle
    !! @param[out]  node_coords  node reference coordinates
    !!
    !! @see @ref trixi_load_node_reference_coordinates_api_c "trixi_load_node_reference_coordinates (C API)"
    subroutine trixi_load_node_reference_coordinates(handle, node_coords) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
      real(c_double), dimension(*), intent(out) :: node_coords
    end subroutine

    !>
    !! @fn LibTrixi::trixi_load_node_weights::trixi_load_node_weights(handle, node_weights)
    !!
    !! @brief Get weights of 1D quadrature nodes.
    !!
    !! The weights of the quadrature nodes in the current DG scheme are stored in the provided
    !! array `node_weights`. The given array has to be of correct size, i.e. `nnodes`, and
    !! memory has to be allocated beforehand.
    !!
    !! @param[in]   handle        simulation handle
    !! @param[out]  node_weights  node weights
    !!
    !! @see @ref trixi_load_node_weights_api_c "trixi_load_node_weights (C API)"
    subroutine trixi_load_node_weights(handle, node_weights) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
      real(c_double), dimension(*), intent(out) :: node_weights
    end subroutine

    !>
    !! @fn LibTrixi::trixi_load_primitive_vars::trixi_load_primitive_vars(handle, variable_id, data)
    !!
    !! @brief Load primitive variable
    !!
    !! @param[in]  handle       simulation handle
    !! @param[in]  variable_id  index of variable
    !! @param[out] data         primitive variable values for all degrees of freedom
    !!
    !! @see @ref trixi_load_primitive_vars_api_c "trixi_load_primitive_vars (C API)"
    subroutine trixi_load_primitive_vars(handle, variable_id, data) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
      integer(c_int), value, intent(in) :: variable_id
      real(c_double), dimension(*), intent(out) :: data
    end subroutine

    !>
    !! @fn LibTrixi::trixi_get_simulation_time::trixi_get_simulation_time(handle)
    !!
    !! @brief Return current physical time.
    !!
    !! @param[in]  handle  simulation handle
    !!
    !! @return  physical time
    !!
    !! @see @ref trixi_get_simulation_time_api_c "trixi_get_simulation_time (C API)"
    real(c_double) function trixi_get_simulation_time(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
    end function

    !>
    !! @fn LibTrixi::trixi_load_element_averaged_primitive_vars::trixi_load_element_averaged_primitive_vars(handle, variable_id, data)
    !!
    !! @brief Load element averages for primitive variable
    !!
    !! @param[in]  handle       simulation handle
    !! @param[in]  variable_id  index of variable
    !! @param[out] data         averaged values for all elements
    !!
    !! @see @ref trixi_load_element_averaged_primitive_vars_api_c "trixi_load_element_averaged_primitive_vars (C API)"
    subroutine trixi_load_element_averaged_primitive_vars(handle, variable_id, data) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
      integer(c_int), value, intent(in) :: variable_id
      real(c_double), dimension(*), intent(out) :: data
    end subroutine

    !>
    !! @fn LibTrixi::trixi_register_data::trixi_register_data(handle, variable_id, data)
    !!
    !! @brief Store data vector in current simulation's registry
    !!
    !! @param[in]  handle  simulation handle
    !! @param[in]  index   index in registry where data vector will be stored
    !! @param[in]  size    size of given data vector
    !! @param[in]  data    data vector to store
    !!
    !! @see @ref trixi_register_data_api_c "trixi_register_data (C API)"
    subroutine trixi_register_data(handle, index, size, data) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_double
      integer(c_int), value, intent(in) :: handle
      integer(c_int), value, intent(in) :: index
      integer(c_int), value, intent(in) :: size
      real(c_double), dimension(*), intent(in) :: data
    end subroutine

    !>
    !! @anchor trixi_get_data_pointer_api_c
    !!
    !! @brief Return pointer to internal data vector.
    !!
    !! The returned pointer points to the beginning of the internal data array used in
    !! Trixi.jl. This array contains the conservative variables, i.e. density, momentum
    !! density in the three Cartesian coordinates, and energy density, in this sequence.
    !! The pointer can be used to read, but also to write these variables. The latter
    !! should be done with care. Writing while a time step in being performed will lead to
    !! undefined behavior.
    !!
    !! @param[in]  handle  simulation handle
    type (c_ptr) function trixi_get_data_pointer(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_ptr
      integer(c_int), value, intent(in) :: handle
    end function



    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! t8code                                                                             !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !>
    !! @fn LibTrixi::trixi_get_t8code_forest::trixi_get_t8code_forest(handle)
    !!
    !! @brief Get t8code forest
    !!
    !! @param[in]  handle       simulation handle
    !!
    !! @return t8code forest
    !!
    !! @see @ref trixi_get_t8code_forest_api_c "trixi_get_t8code_forest (C API)"
    type (c_ptr) function trixi_get_t8code_forest(handle) bind(c)
      use, intrinsic :: iso_c_binding, only: c_int, c_ptr
      integer(c_int), value, intent(in) :: handle
    end function



    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! Misc                                                                               !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !>
    !! @fn LibTrixi::trixi_eval_julia_c::trixi_eval_julia_c(code)
    !!
    !! @brief Execute Julia code (C char pointer version)
    !!
    !! @warning Only for development. Code is not checked prior to execution.
    !!
    !! @see @ref trixi_eval_julia       "trixi_eval_julia_c (Fortran convenience version)"
    !! @see @ref trixi_eval_julia_api_c "trixi_eval_julia_c (C API)"
    subroutine trixi_eval_julia_c(code) bind(c, name='trixi_eval_julia')
      use, intrinsic :: iso_c_binding, only: c_char
      character(kind=c_char), dimension(*), intent(in) :: code
    end subroutine
  end interface

  contains

  !>
  !! @brief Initialize Julia runtime environment (Fortran convenience version)
  !!
  !! @param[in]  project_directory  Path to project directory (Fortran string).
  !! @param[in]  depot_path         Path to Julia depot path (Fortran string).
  !!
  !! @see @ref trixi_initialize_c::trixi_initialize_c
  !!           "trixi_initialize_c (C char pointer version)"
  !! @see @ref trixi_initialize_api_c
  !!           "trixi_initialize (C API)"
  subroutine trixi_initialize(project_directory, depot_path)
    use, intrinsic :: iso_c_binding, only: c_null_char
    character(len=*), intent(in) :: project_directory
    character(len=*), intent(in), optional :: depot_path

    if (present(depot_path)) then
      call trixi_initialize_c(trim(adjustl(project_directory)) // c_null_char, &
                              trim(adjustl(depot_path)) // c_null_char)
    else
      call trixi_initialize_c(trim(adjustl(project_directory)) // c_null_char)
    end if
  end subroutine

  !>
  !! @brief Return full version string of libtrixi (Fortran convenience version).
  !!
  !! @return Full version string as Fortran allocatable string.
  !!
  !! @see @ref trixi_version_library_c::trixi_version_library_c
  !!           "trixi_version_library_c (C char pointer version)"
  !! @see @ref trixi_version_library_api_c
  !!           "trixi_version_library (C API)"
  function trixi_version_library()
    use, intrinsic :: iso_c_binding, only: c_char, c_null_char, c_f_pointer
    character(len=:), allocatable :: trixi_version_library
    character(len=128, kind=c_char), pointer :: buffer
    integer :: length, i

    ! Associate buffer with C pointer
    call c_f_pointer(trixi_version_library_c(), buffer)

    ! Determine the actual length of the version string
    length = 0
    do i = 1,128
      if ( buffer(i:i) == c_null_char ) exit
      length = length + 1
    end do

    ! Store relevant part in return value
    trixi_version_library = buffer(1:(length + 1))
  end function

  !>
  !! @brief Return name and version of loaded julia packages LibTrixi directly depends on
  !!        (Fortran convenience version).
  !!
  !! @return Name and version of loaded julia packages as Fortran allocatable string.
  !!
  !! @see @ref trixi_version_julia_c::trixi_version_julia_c
  !!           "trixi_version_julia_c (C char pointer version)"
  !! @see @ref trixi_version_julia_api_c
  !!           "trixi_version_julia (C API)"
  function trixi_version_julia()
    use, intrinsic :: iso_c_binding, only: c_char, c_null_char, c_f_pointer
    character(len=:), allocatable :: trixi_version_julia
    character(len=1024, kind=c_char), pointer :: buffer
    integer :: length, i

    ! Associate buffer with C pointer
    call c_f_pointer(trixi_version_julia_c(), buffer)

    ! Determine the actual length of the version string
    length = 0
    do i = 1,1024
      if ( buffer(i:i) == c_null_char ) exit
      length = length + 1
    end do

    ! Store relevant part in return value
    trixi_version_julia = buffer(1:(length + 1))
  end function

  !>
  !! @brief Return name and version of all loaded julia packages
  !!        (Fortran convenience version).
  !!
  !! @return Name and version of loaded julia packages as Fortran allocatable string.
  !!
  !! @see @ref trixi_version_julia_extended_c::trixi_version_julia_extended_c
  !!           "trixi_version_julia_extended_c (C char pointer version)"
  !! @see @ref trixi_version_julia_extended_api_c
  !!           "trixi_version_julia_extended (C API)"
  function trixi_version_julia_extended()
    use, intrinsic :: iso_c_binding, only: c_char, c_null_char, c_f_pointer
    character(len=:), allocatable :: trixi_version_julia_extended
    character(len=8192, kind=c_char), pointer :: buffer
    integer :: length, i

    ! Associate buffer with C pointer
    call c_f_pointer(trixi_version_julia_extended_c(), buffer)

    ! Determine the actual length of the version string
    length = 0
    do i = 1,8192
      if ( buffer(i:i) == c_null_char ) exit
      length = length + 1
    end do

    ! Store relevant part in return value
    trixi_version_julia_extended = buffer(1:(length + 1))
  end function

  !>
  !! @brief Set up Trixi simulation (Fortran convencience version)
  !!
  !! @param[in]  libelixir  Path to libelexir file.
  !!
  !! @return handle (integer) to Trixi simulation instance
  !!
  !! @see @ref trixi_initialize_simulation_c::trixi_initialize_simulation_c
  !!           "trixi_initialize_simulation_c (C char pointer version)"
  !! @see @ref trixi_initialize_simulation_api_c
  !!           "trixi_initialize_simulation (C API)"
  integer(c_int) function trixi_initialize_simulation(libelixir)
    use, intrinsic :: iso_c_binding, only: c_int, c_null_char
    character(len=*), intent(in) :: libelixir

    trixi_initialize_simulation = trixi_initialize_simulation_c(trim(adjustl(libelixir)) // c_null_char)
  end function

  !>
  !! @brief Check if simulation is finished (Fortran convenience version)
  !!
  !! @param[in]  handle  simulation handle
  !!
  !! @return true if finished, false if not
  !!
  !! @see @ref trixi_is_finished_c::trixi_is_finished_c
  !!           "trixi_is_finished (C integer version)"
  !! @see @ref trixi_is_finished_api_c
  !!           "trixi_is_finished (C API)"
  logical function trixi_is_finished(handle)
    use, intrinsic :: iso_c_binding, only: c_int
    integer(c_int), intent(in) :: handle

    trixi_is_finished = trixi_is_finished_c(handle) == 1
  end function

  !>
  !! @brief Execute Julia code (Fortran convenience version)
  !!
  !! @warning Only for development. Code is not checked prior to execution.
  !!
  !! @see @ref trixi_eval_julia_c::trixi_eval_julia_c
  !!           "trixi_eval_julia_c (C char pointer version)"
  !! @see @ref trixi_eval_julia_api_c
  !!           "trixi_eval_julia_c (C API)"
  subroutine trixi_eval_julia(code)
    use, intrinsic :: iso_c_binding, only: c_null_char
    character(len=*), intent(in) :: code

    call trixi_eval_julia_c(trim(adjustl(code)) // c_null_char)
  end subroutine
  
end module

!>
!! @}