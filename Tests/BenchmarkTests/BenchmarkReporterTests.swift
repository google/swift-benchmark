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
        _ results: [BenchmarkResult],
        _ expected: String,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let output = MockTextOutputStream()
        var reporter = ConsoleReporter(output: output)
        reporter.report(results: results)
        assertReported(output.result(), expected, message(), file: file, line: line)
    }

    func assertJSONReported(
        _ results: [BenchmarkResult],
        _ expected: String,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let output = MockTextOutputStream()
        var reporter = JSONReporter(output: output)
        reporter.report(results: results)
        assertReported(output.result(), expected, message(), file: file, line: line)
    }

    func assertCSVReported(
        _ results: [BenchmarkResult],
        _ expected: String,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let output = MockTextOutputStream()
        var reporter = CSVReporter(output: output)
        reporter.report(results: results)
        assertReported(output.result(), expected, message(), file: file, line: line)
    }

    func assertReported(
        _ got: String,
        _ expected: String,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        func trimmingTrailingWhitespace(_ string: String) -> String {
            String(string.reversed().drop(while: { $0.isWhitespace }).reversed())
        }
        let lines = Array(got.split(separator: "\n").map { String($0) })
        let expectedLines = expected.split(separator: "\n").map { String($0) }
        let actual = lines.map { $0.trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }
        XCTAssertEqual(expectedLines.count, actual.count, message(), file: file, line: line)
        for (expectedLine, actualLine) in zip(expectedLines, actual) {
            let trimmedExpectedLine = trimmingTrailingWhitespace(expectedLine)
            let trimmedActualLine = trimmingTrailingWhitespace(actualLine)
            XCTAssertEqual(trimmedExpectedLine, trimmedActualLine, message(), file: file, line: line)
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
            name         time           std        iterations
            -------------------------------------------------
            MySuite.fast    1500.000 ns ±  47.14 %          2
            MySuite.slow 1500000.000 ns ±  47.14 %          2
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
            name         time           std        iterations foo
            -----------------------------------------------------
            MySuite.fast    1500.000 ns ±  47.14 %          2   7
            MySuite.slow 1500000.000 ns ±  47.14 %          2   0
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
            name         time           std        iterations warmup
            -----------------------------------------------------------
            MySuite.fast    1500.000 ns ±  47.14 %          2 60.000 ns
            MySuite.slow 1500000.000 ns ±  47.14 %          2  0.000 ns
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
            name       time             std        iterations
            -------------------------------------------------
            MySuite.ns 123456789.000 ns ±   0.00 %          1
            MySuite.us    123456.789 us ±   0.00 %          1
            MySuite.ms       123.457 ms ±   0.00 %          1
            MySuite.s          0.123  s ±   0.00 %          1
            """#
        assertConsoleReported(results, expected)
    }

    func testConsoleMixedColumns() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "min"])]]),
                measurements: [1_000, 2_000],
                warmupMeasurements: [10, 20, 30],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "max"])]]),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name         min         max
            ---------------------------------------
            MySuite.fast 1000.000 ns                          
            MySuite.slow             2000000.000 ns
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
                    settings: BenchmarkSettings([defaultSettings, [Columns(["name"])]]),
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
        assertJSONReported(results, expected)
    }

    func testJSONTimeUnit() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "ns", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.ns), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "us", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.us), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "ms", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.ms), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "s", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.s), Columns(["name", "time"])],
                ]),
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
        assertJSONReported(results, expected)
    }

    func testJSONMixedColumns() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "min"])]]),
                measurements: [1_000, 2_000],
                warmupMeasurements: [10, 20, 30],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "max"])]]),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            {
              "benchmarks": [
                {
                  "name": "MySuite.fast",
                  "min": 1000.0,
                },
                {
                  "name": "MySuite.slow",
                  "max": 2000000.0
                }
              ]
            }
            """#
        assertJSONReported(results, expected)
    }

    func testCSVEmpty() {
        let results: [BenchmarkResult] = []
        let expected = ""
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
                    settings: BenchmarkSettings([defaultSettings, [Columns(["name", "time"])]]),
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
        assertCSVReported(results, expected)
    }

    func testCSVTimeUnit() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "ns", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.ns), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "us", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.us), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "ms", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.ms), Columns(["name", "time"])],
                ]),
                measurements: [123_456_789],
                warmupMeasurements: [],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "s", suiteName: "MySuite",
                settings: BenchmarkSettings([
                    defaultSettings, [TimeUnit(.s), Columns(["name", "time"])],
                ]),
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
        assertCSVReported(results, expected)
    }

    func testCSVMixedColumns() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "min"])]]),
                measurements: [1_000, 2_000],
                warmupMeasurements: [10, 20, 30],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "MySuite",
                settings: BenchmarkSettings([defaultSettings, [Columns(["name", "max"])]]),
                measurements: [1_000_000, 2_000_000],
                warmupMeasurements: [],
                counters: [:]),
        ]
        let expected = #"""
            name,min,max
            MySuite.fast,1000.0,
            MySuite.slow,,2000000.0
            """#
        assertCSVReported(results, expected)
    }

    static var allTests = [
        ("testConsoleBasic", testConsoleBasic),
        ("testConsoleCounters", testConsoleCounters),
        ("testConsoleWarmup", testConsoleWarmup),
        ("testConsoleTimeUnit", testConsoleTimeUnit),
        ("testConsoleMixedColumns", testConsoleMixedColumns),
        ("testJSONEmpty", testJSONEmpty),
        ("testJSONBasic", testJSONBasic),
        ("testJSONEscape", testJSONEscape),
        ("testJSONTimeUnit", testJSONTimeUnit),
        ("testJSONMixedColumns", testJSONMixedColumns),
        ("testCSVEmpty", testCSVEmpty),
        ("testCSVBasic", testCSVBasic),
        ("testCSVEscape", testCSVEscape),
        ("testCSVTimeUnit", testCSVTimeUnit),
        ("testCSVMixedColumns", testCSVMixedColumns),
    ]
}
