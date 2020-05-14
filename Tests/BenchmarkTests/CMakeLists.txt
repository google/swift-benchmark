add_library(BenchmarkTests
  BenchmarkCommandTests.swift
  BenchmarkRunnerTests.swift
  BenchmarkSettingTests.swift
  BlackHoleReporter.swift
  StatsTests.swift
  XCTTestManifests.swift)
target_link_libraries(BenchmarkTests PUBLIC
  Benchmark
  Foundation
  XCTest)
