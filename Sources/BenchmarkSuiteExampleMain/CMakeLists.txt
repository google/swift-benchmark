add_executable(BenchmarkSuiteExampleMain
  main.swift)
target_link_libraries(BenchmarkSuiteExample PRIVATE
  Benchmark
  BenchmarkSuiteExample)
