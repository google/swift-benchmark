add_library(BenchmarkTests
  BenchmarkColumnTests.swift
  BenchmarkCommandTests.swift
  BenchmarkReporterTests.swift
  BenchmarkRunnerTests.swift
  BenchmarkSettingTests.swift
  BenchmarkSuiteTests.swift
  CustomBenchmarkTests.swift
  MockTextOutputStream.swift
  StatsTests.swift
  XCTTestManifests.swift)

target_link_libraries(BenchmarkTests PUBLIC
  Benchmark
  BenchmarkSuiteExample
  Foundation
  XCTest)
