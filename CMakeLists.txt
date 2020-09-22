cmake_minimum_required(VERSION 3.16.0)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(swift-benchmark
  LANGUAGES Swift)

option(BUILD_SHARED_LIBS "build shared libraries by default" YES)
option(BUILD_EXAMPLES "build examples" NO)

include(CTest)
include(ExternalProject)
include(SwiftSupport)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

find_package(dispatch CONFIG QUIET)
find_package(Foundation CONFIG QUIET)

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  set(_copy_swift_argument_parser_import_library
    ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/Sources/ArgumentParser/${CMAKE_IMPORT_LIBRARY_PREFIX}ArgumentParser${CMAKE_IMPORT_LIBRARY_SUFFIX} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/)
endif()
ExternalProject_Add(swift-argument-parser
  GIT_REPOSITORY git://github.com/apple/swift-argument-parser.git
  GIT_TAG master
  CMAKE_ARGS
    -DBUILD_SHARED_LIBS=YES
    -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
    -DCMAKE_Swift_COMPILER=${CMAKE_Swift_COMPILER}
    -DCMAKE_Swift_FLAGS=${CMAKE_Swift_FLAGS}
    -DBUILD_EXAMPLES=NO
    -DBUILD_TESTING=NO
  INSTALL_COMMAND
    COMMAND
      ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/lib/${CMAKE_SHARED_LIBRARY_PREFIX}ArgumentParser${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/
    COMMAND
      ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/swift/ArgumentParser.swiftmodule ${CMAKE_Swift_MODULE_DIRECTORY}/
    COMMAND
      ${_copy_swift_argument_parser_import_library}
  BUILD_BYPRODUCTS
    <BINARY_DIR>/Sources/ArgumentParser/${CMAKE_SHARED_LIBRARY_PREFIX}ArgumentParser${CMAKE_SHARED_LIBRARY_SUFFIX}
    <BINARY_DIR>/Sources/ArgumentParser/${CMAKE_IMPORT_LIBRARY_PREFIX}ArgumentParser${CMAKE_IMPORT_LIBRARY_SUFFIX}
    ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${CMAKE_SHARED_LIBRARY_PREFIX}ArgumentParser${CMAKE_SHARED_LIBRARY_SUFFIX}
    ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_IMPORT_LIBRARY_PREFIX}ArgumentParser${CMAKE_IMPORT_LIBRARY_SUFFIX}
  STEP_TARGETS install)

add_library(ArgumentParser SHARED IMPORTED)
set_target_properties(ArgumentParser PROPERTIES
  IMPORTED_LOCATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${CMAKE_SHARED_LIBRARY_PREFIX}ArgumentParser${CMAKE_SHARED_LIBRARY_SUFFIX}
  IMPORTED_IMPLIB ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_IMPORT_LIBRARY_PREFIX}ArgumentParser${CMAKE_IMPORT_LIBRARY_SUFFIX}
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
add_dependencies(ArgumentParser swift-argument-parser-install)

add_subdirectory(Sources)
if(BUILD_TESTING)
  add_subdirectory(Tests)
endif()
add_subdirectory(cmake/modules)
