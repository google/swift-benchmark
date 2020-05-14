cmake_minimum_required(VERSION 3.16.0)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(swift-benchmark
  LANGUAGES Swift)

option(BUILD_SHARED_LIBS "build shared libraries by default" YES)
option(BUILD_EXAMPLES "build examples" NO)

include(CTest)
include(SwiftSupport)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

find_package(dispatch CONFIG QUIET)
find_package(Foundation CONFIG QUIET)
find_package(ArgumentParser CONFIG QUIET)

add_subdirectory(Sources)
if(BUILD_TESTING)
  add_subdirectory(Tests)
endif()
add_subdirectory(cmake/modules)
