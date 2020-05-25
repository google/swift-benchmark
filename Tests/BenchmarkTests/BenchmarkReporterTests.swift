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
    func testPlainTextReporter() throws {
        let results: [BenchmarkResult] = [
            BenchmarkResult(benchmarkName: "fast", suiteName: "My Suite", measurements: [1_000, 2_000]),
            BenchmarkResult(benchmarkName: "slow", suiteName: "My Suite", measurements: [1_000_000, 2_000_000])

        ]

        let output = MockTextOutputStream()
        var reporter = PlainTextReporter(to: output)

        reporter.report(results: results)

        let expected = """
        name          \ttime        \tstd       \titerations
        --------------\t------------\t----------\t----------
        My Suite: fast\t   1500.0 ns\t±  47.14 %\t         2
        My Suite: slow\t1500000.0 ns\t±  47.14 %\t         2
        """.split(separator: "\n").map { String($0) }

        let actual = output.lines.map {$0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                 .filter { !$0.isEmpty}
        for (expectedLine, actualLine) in zip(expected, actual) {
            XCTAssertEqual(expectedLine, actualLine)
        }
    }

    static var allTests = [
        ("PlainTextReporter", testPlainTextReporter),
    ]
}
