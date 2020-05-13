find_package(XCTest CONFIG QUIET)

add_subdirectory(BenchmarkTests)

add_executable(BenchmarkTestRunner
  LinuxMain.swift)
target_link_libraries(BenchmarkTestRunner PRIVATE
  BenchmarkTests
  XCTest)

add_test(NAME Benchmark
  COMMAND BenchmarkTestRunner)
