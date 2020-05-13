add_executable(BenchmarkSuiteExample
  AddStringBenchmarks.swift
  main.swift)
target_link_libraries(BenchmarkSuiteExample PRIVATE
  Benchmark)
