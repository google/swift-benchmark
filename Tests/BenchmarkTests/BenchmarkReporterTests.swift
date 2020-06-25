// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest

@testable import Benchmark

final class BenchmarkReporterTests: XCTestCase {
    func assertConsoleReported(
        _ results: [BenchmarkResult], _ expected: String,
        settings: BenchmarkSettings = BenchmarkSettings()
    ) {
        let output = MockTextOutputStream()
        var reporter = ConsoleReporter(output: output)
        reporter.report(results: results, settings: settings)
        assertReported(output.result(), expected)
    }

    func assertJSONReported(
        _ results: [BenchmarkResult], _ expected: String,
        settings: BenchmarkSettings = BenchmarkSettings()
    ) {
        let output = MockTextOutputStream()
        var reporter = JSONReporter(output: output)
        reporter.report(results: results, settings: settings)
        assertReported(output.result(), expected)
    }

    func assertCSVReported(
        _ results: [BenchmarkResult], _ expected: String,
        settings: BenchmarkSettings = BenchmarkSettings()
    ) {
        let output = MockTextOutputStream()
        var reporter = CSVReporter(output: output)
        reporter.report(results: results, settings: settings)
        assertReported(output.result(), expected)
    }

    func assertReported(_ got: String, _ expected: String) {
        let lines = Array(got.split(separator: "\n").map { String($0) })
        let expectedLines = expected.split(separator: "\n").map { String($0) }
        let actual = lines.map { $0.trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }
        XCTAssertEqual(expectedLines.count, actual.count)
        for (expectedLine, actualLine) in zip(expectedLines, actual) {
            XCTAssertEqual(expectedLine, actualLine)
        }
    }

    func testConsoleBasic() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000, 2_000],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name         time         std        iterations
            -----------------------------------------------
            MySuite.fast    1500.0 ns ±  47.14 %          2
            MySuite.slow 1500000.0 ns ±  47.14 %          2
            """#
        assertConsoleReported(results, expected)
    }

    func testConsoleCounters() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000, 2_000],
                warmupMeasurements: [],
                counters: ["foo": 7]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name         time         std        iterations foo
            ---------------------------------------------------
            MySuite.fast    1500.0 ns ±  47.14 %          2   7
            MySuite.slow 1500000.0 ns ±  47.14 %          2   0
            """#
        assertConsoleReported(results, expected)
    }

    func testConsoleWarmup() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000, 2_000],
                warmupMeasurements: [10, 20, 30],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name         time         std        iterations warmup 
            -------------------------------------------------------
            MySuite.fast    1500.0 ns ±  47.14 %          2 60.0 ns
            MySuite.slow 1500000.0 ns ±  47.14 %          2  0.0 ns
            """#
        assertConsoleReported(results, expected)
    }

    func testConsoleTimeUnit() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "ns", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ns)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "us", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.us)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "ms", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ms)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "s", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.s)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name       time           std        iterations
            -----------------------------------------------
            MySuite.ns 123456789.0 ns ±   0.00 %          1
            MySuite.us  123456.789 us ±   0.00 %          1
            MySuite.ms  123.456789 ms ±   0.00 %          1
            MySuite.s   0.123456789 s ±   0.00 %          1
            """#
        assertConsoleReported(results, expected)
    }

    func testJSONEmpty() {
        let results: [BenchmarkResult] = []
        let expected = #"""
            {
              "benchmarks": [
              ]
            }
            """#
        assertJSONReported(results, expected)
    }

    func testJSONBasic() {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000, 2_000],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            {
              "benchmarks": [
                {
                  "name": "MySuite.fast",
                  "time": 1500.0,
                  "std": 47.14045207910317,
                  "iterations": 2.0
                },
                {
                  "name": "MySuite.slow",
                  "time": 1500000.0,
                  "std": 47.14045207910317,
                  "iterations": 2.0
                }
              ]
            }
            """#
        assertJSONReported(results, expected)
    }

    func testJSONEscape() {
        var results: [BenchmarkResult] = []
        for name in ["\"", "\t", "\r", "\n"] {
            results.append(
                BenchmarkResult(
                    benchmarkName: name, suiteName: "",
                    settings: BenchmarkSettings(),
                    measurements: [],
                    warmupMeasurements: [],
                    counters: [:]))
        }
        let expected = #"""
            {
              "benchmarks": [
                {
                  "name": "\""
                },
                {
                  "name": "\t"
                },
                {
                  "name": "\r"
                },
                {
                  "name": "\n"
                }
              ]
            }
            """#
        let settings = BenchmarkSettings([Columns(["name"])])
        assertJSONReported(results, expected, settings: settings)
    }

    func testJSONTimeUnit() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "ns", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ns)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "us", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.us)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "ms", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ms)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "s", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.s)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            {
              "benchmarks": [
                {
                  "name": "MySuite.ns",
                  "time": 123456789.0
                },
                {
                  "name": "MySuite.us",
                  "time": 123456.789
                },
                {
                  "name": "MySuite.ms",
                  "time": 123.456789
                },
                {
                  "name": "MySuite.s",
                  "time": 0.123456789
                }
              ]
            }
            """#
        let settings = BenchmarkSettings([Columns(["name", "time"])])
        assertJSONReported(results, expected, settings: settings)
    }

    func testCSVEmpty() {
        let results: [BenchmarkResult] = []
        let expected = #"""
            name,time,std,iterations
            """#
        assertCSVReported(results, expected)
    }

    func testCSVBasic() {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000, 2_000],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings(),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name,time,std,iterations
            MySuite.fast,1500.0,47.14045207910317,2.0
            MySuite.slow,1500000.0,47.14045207910317,2.0
            """#
        assertCSVReported(results, expected)
    }

    func testCSVEscape() {
        var results: [BenchmarkResult] = []
        for name in [",", "\"", "\n"] {
            results.append(
                BenchmarkResult(
                    benchmarkName: name, suiteName: "",
                    settings: BenchmarkSettings(),
                    measurements: [1_000, 2_000],
                    warmupMeasurements: [],
                    counters: [:]))
        }
        let expected = #"""
            name,time
            ",",1500.0
            """",1500.0
            "
            ",1500.0
            """#
        let settings = BenchmarkSettings([Columns(["name", "time"])])
        assertCSVReported(results, expected, settings: settings)
    }

    func testCSVTimeUnit() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "ns", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ns)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "us", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.us)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "ms", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.ms)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "s", suiteName: "MySuite",
                settings: BenchmarkSettings([TimeUnit(.s)]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name,time
            MySuite.ns,123456789.0
            MySuite.us,123456.789
            MySuite.ms,123.456789
            MySuite.s,0.123456789
            """#
        let settings = BenchmarkSettings([Columns(["name", "time"])])
        assertCSVReported(results, expected, settings: settings)
    }

    static var allTests = [
        ("testConsoleBasic", testConsoleBasic),
        ("testConsoleCounters", testConsoleCounters),
        ("testConsoleWarmup", testConsoleWarmup),
        ("testConsoleTimeUnit", testConsoleTimeUnit),
        ("testJSONEmpty", testJSONEmpty),
        ("testJSONBasic", testJSONBasic),
        ("testJSONEscape", testJSONEscape),
        ("testJSONTimeUnit", testJSONTimeUnit),
        ("testCSVEmpty", testCSVEmpty),
        ("testCSVBasic", testCSVBasic),
        ("testCSVEscape", testCSVEscape),
        ("testCSVTimeUnit", testCSVTimeUnit),
    ]
}
