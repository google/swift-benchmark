set(Benchmark_EXPORTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/BenchmarkExports.cmake)

configure_file(BenchmarkConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/BenchmarkConfig.cmake)

get_property(Benchmark_EXPORTS GLOBAL PROPERTY Benchmark_EXPORTS)
export(TARGETS ${Benchmark_EXPORTS}
  FILE ${Benchmark_EXPORTS_FILE})
