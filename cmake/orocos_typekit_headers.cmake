include(CMakeParseArguments)

if(CMAKE_MAJOR_VERSION LESS 3)
  include(${CMAKE_CURRENT_LIST_DIR}/orocos_typekit_headers-cmake2-helpers.cmake)
endif()

macro(orocos_generate_typekit_headers name target_dir)
  # For now there can be only one typekit per package:
  if(DEFINED ${PROJECT_NAME}_TYPEKITS)
    message(SEND_ERROR "orocos_generate_typekit() / orocos_generate_typekit_headers() can only be called once per CMake project!")
    return()
  endif()

  set(_target_dir ${target_dir})
  set(_typekit_NAME ${name})
  set(_typekit_PROJECT_NAME ${name})
  set(_typekit_TARGET ${name})
  string(REPLACE "-" "_" _typekit_CNAME ${_typekit_NAME})
  cmake_parse_arguments(_typekit "" "NAME" "HEADERS;TYPES;NAMES;DEPENDS" ${ARGN})
  if(NOT DEFINED _typekit_NAME)
    set(_typekit_NAME ${name})
  endif()
  if(NOT DEFINED _typekit_INCLUDE_DIRS)
    get_directory_property(_typekit_INCLUDE_DIRS INCLUDE_DIRECTORIES)
  endif()

  # automatically assign type names if none were given by the user
  list(LENGTH _typekit_TYPES _typekit_TYPES_length1)
  math(EXPR _typekit_TYPES_length2 "${_typekit_TYPES_length1} - 1")
  if(NOT DEFINED _typekit_NAMES)
    set(_typekit_NAMES)
    foreach(_i RANGE ${_typekit_TYPES_length2})
      list(GET _typekit_TYPES ${_i} _type)
      string(REPLACE "::" "/" _name ${_type})
      set(_name "/${_name}")
      list(APPEND _typekit_NAMES ${_name})
    endforeach()
  endif()

  message(STATUS "Generating RTT typekit '${_typekit_NAME}' for types:")
  foreach(_i RANGE ${_typekit_TYPES_length2})
    list(GET _typekit_TYPES ${_i} _type)
    list(GET _typekit_NAMES ${_i} _name)
    message(STATUS "- ${_name} (${_type})")
  endforeach()

  # set default values from ${PROJECT_NAME}
  if(NOT DEFINED _typekit_VERSION)
    if (DEFINED ${PROJECT_NAME}_VERSION)
      set(_typekit_VERSION ${${PROJECT_NAME}_VERSION})
    else()
      set(_typekit_VERSION "0.0.0")
    endif()
  endif()
#  if(NOT DEFINED _typekit_MAINTAINER)
#    if(DEFINED ${PROJECT_NAME}_MAINTAINER)
#      set(_typekit_MAINTAINER ${${PROECT_NAME}_MAINTAINER})
#    else()
#      set(_typekit_MAINTAINER "Unknown <unknown@unknown.com>")
#    endif()
#  endif()
#  if(NOT DEFINED _typekit_LICENSE)
#    set(_typekit_LICENSE "Unknown")
#  endif()

  # create target directories
  file(MAKE_DIRECTORY ${_target_dir})
  file(MAKE_DIRECTORY ${_target_dir}/corba)
  set(_typekit_INCLUDE_DIR ${_target_dir}/include/orocos/${_typekit_NAME}/typekit)
  file(MAKE_DIRECTORY ${_typekit_INCLUDE_DIR})
  include_directories(BEFORE ${_target_dir}/include/orocos)

  # find headers and generate includes.h
  file(WRITE ${_typekit_INCLUDE_DIR}/includes.h "")
  set(_typekit_INCLUDES)
  set(_typekit_HEADERS_ABSOLUTE)
  foreach(_header ${_typekit_HEADERS})
    if(IS_ABSOLUTE ${_header})
      set(_header_ABSOLUTE ${_header})
    else()
      find_file(_header_ABSOLUTE ${_header} PATHS ${_typekit_INCLUDE_DIRS} NO_DEFAULT_PATH)
      if(NOT _header_ABSOLUTE)
        set(_message "Generated typekit '${_typekit_NAME}' depends on header '${_header}', but this header could not be found in one of the following include directories:\n")
        foreach(_include_dir ${_typekit_INCLUDE_DIRS})
          set(_message ${_message} " - ${_include_dir}\n")
        endforeach()
        message(FATAL_ERROR ${_message})
      endif()
    endif()
    list(APPEND _typekit_HEADERS_ABSOLUTE ${_header_ABSOLUTE})
    #file(APPEND ${_typekit_INCLUDE_DIR}/includes.h "#include \"${_header_ABSOLUTE}\"\n")
    file(APPEND ${_typekit_INCLUDE_DIR}/includes.h "#include <${_header}>\n")
    #set(_typekit_INCLUDES "${_typekit_INCLUDES}#include \"${_header_ABSOLUTE}\"\n")
    set(_typekit_INCLUDES "${_typekit_INCLUDES}#include <${_header}>\n")
    unset(_header_ABSOLUTE CACHE)
  endforeach()

  # generate types.h
  file(WRITE ${_typekit_INCLUDE_DIR}/types.h "#define TYPEKIT_NAME \"${_typekit_NAME}\"\n\n")
  list(LENGTH _typekit_TYPES _typekit_TYPES_length1)
  math(EXPR _typekit_TYPES_length2 "${_typekit_TYPES_length1} - 1")
  foreach(_i RANGE ${_typekit_TYPES_length2})
    list(GET _typekit_TYPES ${_i} _type)
    list(GET _typekit_NAMES ${_i} _name)
    if(NOT _name)
      string(REPLACE "::" "." _name ${_type})
    endif()
    file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define TYPE${_i} ${_type}\n")
    file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define TYPE_NAME${_i} \"${_name}\"\n")
    file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define C_TYPE_NAME${_i} \"${_type}\"\n")
  endforeach()
  file(APPEND ${_typekit_INCLUDE_DIR}/types.h "\n#define TYPE_CNT ${_typekit_TYPES_length1}\n")
  file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define TYPE_NAME_CNT ${_typekit_TYPES_length1}\n")
  file(APPEND ${_typekit_INCLUDE_DIR}/types.h "\n#define TYPE(i) TYPE ## i\n")
  file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define TYPE_NAME(i) TYPE_NAME ## i\n")
  file(APPEND ${_typekit_INCLUDE_DIR}/types.h "#define C_TYPE_NAME(i) C_TYPE_NAME ## i\n")

  # generate CMakeLists.txt
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/CMakeLists.txt.in ${_target_dir}/CMakeLists.txt @ONLY)
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/corba/CMakeLists.txt.in ${_target_dir}/corba/CMakeLists.txt @ONLY)

  # generate Types.hpp
  set(_typekit_EXTERN_TEMPLATE_DECLARATIONS)
  foreach(_i RANGE ${_typekit_TYPES_length2})
    list(GET _typekit_TYPES ${_i} _type)
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::internal::DataSource< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::internal::AssignableDataSource< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::internal::ValueDataSource< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::internal::ConstantDataSource< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::internal::ReferenceDataSource< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::OutputPort< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::InputPort< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::Property< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}extern template class RTT_EXPORT RTT::Attribute< ${_type} >;\n")
    set(_typekit_EXTERN_TEMPLATE_DECLARATIONS "${_typekit_EXTERN_TEMPLATE_DECLARATIONS}\n")
  endforeach()
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/Types.hpp.in ${_typekit_INCLUDE_DIR}/Types.hpp @ONLY)

  if(ORO_USE_CATKIN)
    file(COPY
      ${_typekit_INCLUDE_DIR}/includes.h
      ${_typekit_INCLUDE_DIR}/types.h
      ${_typekit_INCLUDE_DIR}/Types.hpp
      DESTINATION ${CATKIN_DEVEL_PREFIX}/include/orocos/${_typekit_NAME}/typekit
    )
  endif()

  # generate typekit plugin
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/typekit.cpp.in ${_target_dir}/typekit.cpp @ONLY)

  # generate CORBA transport plugin
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/corba/transport.cpp.in ${_target_dir}/corba/transport.cpp @ONLY)

  # create stand-alone introspection library
  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/introspection.cpp.in ${_target_dir}/introspection.cpp @ONLY)
  add_library(${_typekit_TARGET}_introspection SHARED ${_target_dir}/introspection.cpp)

  # create generator target
#  configure_file(${rtt_typekit_generator_TEMPLATES_DIR}/generator.cpp.in ${_target_dir}/generator.cpp @ONLY)
  add_executable(${_typekit_TARGET}_generator
#    ${_target_dir}/generator.cpp
    ${rtt_typekit_generator_SOURCE_DIR}/generator.cpp
    ${rtt_typekit_generator_SOURCE_DIR}/transports/corba.cpp
  )
  target_compile_options(${_typekit_TARGET}_generator PRIVATE
    -include ${_typekit_INCLUDE_DIR}/includes.h
    -include ${_typekit_INCLUDE_DIR}/types.h
  )
  target_link_libraries(${_typekit_TARGET}_generator ${Boost_FILESYSTEM_LIBRARY} ${Boost_SYSTEM_LIBRARY})
  set_target_properties(${_typekit_TARGET}_generator PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_target_dir})
  get_target_property(${_typekit_TARGET}_generator_LOCATION ${_typekit_TARGET}_generator LOCATION)

  # create generate target
  add_custom_command(
    OUTPUT ${_target_dir}/stamp
    COMMAND ${${_typekit_TARGET}_generator_LOCATION}
    COMMAND touch stamp
    DEPENDS ${_typekit_TARGET}_generator ${_typekit_HEADERS_ABSOLUTE}
    WORKING_DIRECTORY "${_target_dir}"
    VERBATIM
    COMMENT "Generating code for typekit ${name}..."
  )
  add_custom_target(${name}_generate_typekit ALL
    DEPENDS ${_target_dir}/stamp
  )

  # add generated typekit to the clean target
#  set_property(DIRECTORY
#    APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
#    ${_target_dir}/types.h
#    ${_target_dir}/includes.h
#    ${_target_dir}/CMakeLists.txt
#    ${_target_dir}/Types.hpp
#    ${_target_dir}/typekit.cpp
#    ${_target_dir}/introspection.cpp
#    ${_target_dir}/generator.cpp
#  )

  # export some variables
  set(${name}_OUTPUT_DIRECTORY ${_target_dir})
  set(${name}_EXPORTED_TARGETS ${name}_generate_typekit)
  set(${PROJECT_NAME}_TYPEKITS ${${PROJECT_NAME}_TYPEKITS} ${_name})
  set(${PROJECT_NAME}_TYPEKIT_TYPES ${${PROJECT_NAME}_TYPEKIT_TYPES} ${_typekit_TYPES})

  # cleanup internal variables
  unset(_header)
  unset(_header_ABSOLUTE)
  unset(_message)
  unset(_name)
  unset(_target_dir)
  unset(_type)
  unset(_typekit_CNAME)
  unset(_typekit_DEPENDS)
  unset(_typekit_EXTERN_TEMPLATE_DECLARATIONS)
  unset(_typekit_HEADERS)
  unset(_typekit_HEADERS_ABSOLUTE)
  unset(_typekit_INCLUDES)
  unset(_typekit_NAME)
  unset(_typekit_NAMES)
  unset(_typekit_PROJECT_NAME)
  unset(_typekit_TARGET)
  unset(_typekit_TYPES)
  unset(_typekit_TYPES_length1)
  unset(_typekit_TYPES_length2)
  unset(_typekit_VERSION)
endmacro()

#macro(orocos_typekit_headers name)
#  # Generate the typekit
#  orocos_generate_typekit_headers(${name} "${CMAKE_CURRENT_BINARY_DIR}/${name}" ${ARGN})

#  # Export the cmake environment for the deferred build step
#  _export_cache("${${name}_OUTPUT_DIRECTORY}/cache.cmake")
#  _export_variables("${${name}_OUTPUT_DIRECTORY}/variables.cmake" CACHE INTERNAL "\"\"")

#  # Build the typekit
#  add_custom_command(
#    OUTPUT "${${name}_OUTPUT_DIRECTORY}/build"
#    COMMAND "${CMAKE_COMMAND}"
#      -E make_directory "${${name}_OUTPUT_DIRECTORY}/build"
#    COMMENT "Creating build directory..."
#    VERBATIM
#  )
#  add_custom_command(
#    OUTPUT "${${name}_OUTPUT_DIRECTORY}/build/CMakeCache.txt"
#    COMMAND "${CMAKE_COMMAND}"
#      #"--trace"
#      #-C "${${name}_OUTPUT_DIRECTORY}/cache.cmake"
#      -C "${${name}_OUTPUT_DIRECTORY}/variables.cmake"
#      -UCMAKE_HOME_DIRECTORY
#      -DUSE_OROCOS_RTT=False
#      -DORO_USE_ROSBUILD=OFF
#      -DORO_USE_CATKIN=OFF
#      "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
#      ..
#    DEPENDS ${${name}_EXPORTED_TARGETS} "${${name}_OUTPUT_DIRECTORY}/build"
#    WORKING_DIRECTORY "${${name}_OUTPUT_DIRECTORY}/build"
#    COMMENT "Configuring typekit '${name}'..."
#    VERBATIM
#  )
#  add_custom_target(${name}_configure
#    DEPENDS "${${name}_OUTPUT_DIRECTORY}/build/CMakeCache.txt"
#  )
#  add_custom_target(${name} ALL
#    "${CMAKE_COMMAND}"
#      --build "${${name}_OUTPUT_DIRECTORY}/build"
#    DEPENDS ${name}_configure
#    WORKING_DIRECTORY "${${name}_OUTPUT_DIRECTORY}/build"
#    COMMENT "Building typekit '${name}'..."
#    VERBATIM
#  )

#  # Install the typekit
#  install(CODE "execute_process(
#      \"${CMAKE_COMMAND}\"
#      --build \"${${name}_OUTPUT_DIRECTORY}/build\"
#      --target install
#      WORKING_DIRECTORY \"${${name}_OUTPUT_DIRECTORY}/build\"
#    )")

#  # add generated typekit to the clean target
#  set_property(DIRECTORY
#    APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
#    "${${name}_OUTPUT_DIRECTORY}/build"
#  )
#endmacro()

macro(orocos_typekit_headers name)
  # Generate the typekit
  orocos_generate_typekit_headers(${name} "${CMAKE_CURRENT_BINARY_DIR}/${name}" ${ARGN})
  add_subdirectory("${CMAKE_CURRENT_BINARY_DIR}/${name}" ${name})
#  orocos_typekit(${name} "${CMAKE_CURRENT_BINARY_DIR}/${name}/typekit.cpp")
#  add_dependencies(${name} ${name}_EXPORTED_TARGETS)

#  install(
#    FILES ${${name}_OUTPUT_DIRECTORY}/Types.hpp
#    DESTINATION include/orocos/${PROJECT_NAME}/typekit
#  )
endmacro()
