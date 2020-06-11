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
    func assertIsPrintedAs(_ results: [BenchmarkResult], _ expected: String) {
        let output = MockTextOutputStream()
        var reporter = PlainTextReporter(to: output)

        reporter.report(results: results)

        let expectedLines = expected.split(separator: "\n").map { String($0) }
        let actual = output.lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for (expectedLine, actualLine) in zip(expectedLines, actual) {
            XCTAssertEqual(expectedLine, actualLine)
        }
    }

    func testPlainTextReporter() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "My Suite", measurements: [1_000, 2_000],
                counters: [:]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "My Suite", measurements: [1_000_000, 2_000_000],
                counters: [:]),
        ]
        let expected = #"""
            name           time         std        iterations
            -------------------------------------------------
            My Suite: fast    1500.0 ns ±  47.14 %          2
            My Suite: slow 1500000.0 ns ±  47.14 %          2
            """#
        assertIsPrintedAs(results, expected)

    }

    func testCountersAreReported() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(
                benchmarkName: "fast", suiteName: "My Suite", measurements: [1_000, 2_000],
                counters: ["n": 7]),
            BenchmarkResult(
                benchmarkName: "slow", suiteName: "My Suite", measurements: [1_000_000, 2_000_000],
                counters: [:]),
        ]
        let expected = #"""
            name           time         std        iterations n
            ---------------------------------------------------
            My Suite: fast    1500.0 ns ±  47.14 %          2 7
            My Suite: slow 1500000.0 ns ±  47.14 %          2
            """#
        assertIsPrintedAs(results, expected)
        assertIsPrintedAs(results, expected)
    }

    static var allTests = [
        ("testPlainTextReporter", testPlainTextReporter),
        ("testCountersAreReported", testCountersAreReported),
    ]
}
