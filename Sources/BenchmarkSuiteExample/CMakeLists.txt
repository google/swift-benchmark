add_executable(BenchmarkSuiteExample
  AddStringBenchmarks.swift
  Suites.swift)
target_link_libraries(BenchmarkSuiteExample PRIVATE
  Benchmark)
