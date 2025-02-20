set ( EXAMPLES
      trixi_controller_simple.c
      trixi_controller_simple.f90
      trixi_controller_mpi.c
      trixi_controller_mpi.f90
      trixi_controller_data.c
      trixi_controller_data.f90
      trixi_controller_t8code.c
      trixi_controller_t8code.f90
      trixi_controller_baroclinic.c
      trixi_controller_baroclinic.f90 )

if ( NOT T8CODE_FOUND )
    list( FILTER EXAMPLES EXCLUDE REGEX ".*(t|T)8(c|C)(o|O)(d|D)(e|E).*" )
    list( FILTER EXAMPLES EXCLUDE REGEX "trixi_controller_baroclinic.*" )
endif()

# example standalone library with callback
add_library ( source_terms SHARED
    source_terms.h
    source_terms.c
)
install( TARGETS source_terms )


foreach ( EXAMPLE ${EXAMPLES} )

    get_filename_component ( EXAMPLE_EXT ${EXAMPLE} EXT )
    get_filename_component ( EXAMPLE_BASE ${EXAMPLE} NAME_WE )

    if ( ${EXAMPLE_EXT} STREQUAL ".c" )
        set ( EXAMPLE_LANG "C" )
        set ( TARGET_EXT "c" )
    elseif ( ${EXAMPLE_EXT} STREQUAL ".f90" )
        set ( EXAMPLE_LANG "Fortran" )
        set ( TARGET_EXT "f" )
    else ()
        message( FATAL_ERROR "Cannot handle extension " ${EXAMPLE_EXT} )
    endif()

    # define target
    set ( TARGET_NAME ${EXAMPLE_BASE}_${TARGET_EXT} )
    add_executable ( ${TARGET_NAME} ${EXAMPLE})

    # set libraries to link
    target_link_libraries(
        ${TARGET_NAME}
        PRIVATE MPI::MPI_${EXAMPLE_LANG} ${PROJECT_NAME}
    )
    if ( NOT USE_PACKAGE_COMPILER )
        target_link_libraries( ${TARGET_NAME} PRIVATE ${PROJECT_NAME}_tls )
    endif()
    if ( T8CODE_FOUND )
        target_link_libraries( ${TARGET_NAME} PRIVATE T8CODE::T8 )
    endif()

    # set include directories
    target_include_directories(
        ${TARGET_NAME}
        PRIVATE ${CMAKE_SOURCE_DIR}/src
    )
    if ( T8CODE_FOUND )
        target_include_directories( ${TARGET_NAME} PRIVATE ${T8CODE_ROOT}/include/t8_fortran_interface/ )
    endif()

    # set runtime path for installed binaries
    set_target_properties(
        ${TARGET_NAME}
        PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib"
    )

    # position independent code
    target_compile_options( ${TARGET_NAME} PRIVATE "-fPIC" )

    # enable warnings
    target_compile_options( ${TARGET_NAME} PRIVATE -Wall -Wextra -Werror )

    # add to installation
    install( TARGETS ${TARGET_NAME} )

endforeach()

# install the julia controller example as well
install( FILES trixi_controller_simple.jl DESTINATION share/libtrixi/examples/ )
