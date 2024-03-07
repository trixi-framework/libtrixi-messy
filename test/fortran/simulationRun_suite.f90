module simulationRun_suite
  use LibTrixi
  use testdrive, only : new_unittest, unittest_type, error_type, check
  implicit none
  private

  public :: collect_simulationRun_suite

  character(len=*), parameter, public :: julia_project_path = JULIA_PROJECT_PATH
  character(len=*), parameter, public :: libelixir_path = &
    "../../../LibTrixi.jl/examples/libelixir_p4est2d_dgsem_euler_sedov.jl"

  contains

  !> Collect all exported unit tests
  subroutine collect_simulationRun_suite(testsuite)
    !> Collection of tests
    type(unittest_type), allocatable, intent(out) :: testsuite(:)

    testsuite = [ new_unittest("simulationRun", test_simulationRun) ]
  end subroutine collect_simulationRun_suite

  subroutine test_simulationRun(error)
    type(error_type), allocatable, intent(out) :: error
    integer :: handle, ndims, nelements, nelements_global, nvariables, ndofs_global, &
               ndofs_element, ndofs, size
    logical :: finished_status
    ! dp as defined in test-drive
    integer, parameter :: dp = selected_real_kind(15)
    real(dp) :: dt
    real(dp), dimension(:), allocatable :: data

    ! Initialize Trixi
    call trixi_initialize(julia_project_path)

    ! Set up the Trixi simulation, get a handle
    handle = trixi_initialize_simulation(libelixir_path)
    call check(error, handle, 1)

    ! Do a simulation step
    call trixi_step(handle)

    ! Check time step length
    dt = trixi_calculate_dt(handle)
    call check(error, dt, 0.0032132984504400627_dp)
    
    ! Check finished status
    finished_status = trixi_is_finished(handle)
    call check(error, finished_status, .false.)

    ! Check number of dimensions
    ndims = trixi_ndims(handle)
    call check(error, ndims, 2)

    ! Check number of elements
    nelements = trixi_nelements(handle)
    call check(error, nelements, 256)

    nelements_global = trixi_nelements_global(handle)
    call check(error, nelements_global, 256)

    ! Check number of dofs
    ndofs_element = trixi_ndofs_element(handle)
    call check(error, ndofs_element, 25)

    ndofs = trixi_ndofs(handle)
    call check(error, ndofs, nelements * ndofs_element)

    ndofs_global = trixi_ndofs_global(handle)
    call check(error, ndofs_global, nelements_global * ndofs_element)

    ! Check number of variables
    nvariables = trixi_nvariables(handle)
    call check(error, nvariables, 4)

    ! Check cell averaged values
    size = nelements
    allocate(data(size))
    call trixi_load_cell_averages(data, 1, handle)
    call check(error, data(1),    1.0_dp)
    call check(error, data(94),   0.99833232379996562_dp)
    call check(error, data(size), 1.0_dp)
    deallocate(data)

    ! Check primitive variable values
    size = ndofs
    allocate(data(size))
    call trixi_load_prim(data, 1, handle)
    call check(error, data(1),    1.0_dp)
    call check(error, data(3200), 1.0_dp)
    call check(error, data(size), 1.0_dp)
    deallocate(data)

    ! Finalize Trixi simulation
    call trixi_finalize_simulation(handle)
    
    ! Finalize Trixi
    call trixi_finalize()
  end subroutine test_simulationRun

end module simulationRun_suite
