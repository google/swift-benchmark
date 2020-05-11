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

final class BenchmarkRunnerTests: XCTestCase {
    func testFilterBenchmarksSuffix() throws {
        let options = try BenchmarkRunnerOptions(filter: "b1")
        XCTAssertEqual(Set(["suite1/b1", "suite2/b1"]), runBenchmarks(options: options))
    }

    func testFilterBenchmarksSuiteName() throws {
        let options = try BenchmarkRunnerOptions(filter: "suite1")
        XCTAssertEqual(Set(["suite1/b1", "suite1/b2"]), runBenchmarks(options: options))
    }

    func testFilterBenchmarksFullName() throws {
        let options = try BenchmarkRunnerOptions(filter: "suite1/b1")
        XCTAssertEqual(Set(["suite1/b1"]), runBenchmarks(options: options))
    }

    static var allTests = [
        ("testFilterBenchmarksSuffix", testFilterBenchmarksSuffix),
        ("testFilterBenchmarksSuiteName", testFilterBenchmarksSuiteName),
        ("testFilterBenchmarksFullName", testFilterBenchmarksFullName),
    ]
}

extension BenchmarkRunnerTests {
    /// Builds and runs a few suites of benchmarks with provided options; returns the set of
    /// benchmark names that were run.
    func runBenchmarks(options: BenchmarkRunnerOptions) -> Set<String> {
        let suite1 = BenchmarkSuite(name: "suite1")
        let suite2 = BenchmarkSuite(name: "suite2")

        var benchmarksRun = Set<String>()

        suite1.benchmark("b1") { benchmarksRun.insert("suite1/b1") }
        suite2.benchmark("b1") { benchmarksRun.insert("suite2/b1") }
        suite1.benchmark("b2") { benchmarksRun.insert("suite1/b2") }
        suite2.benchmark("b2") { benchmarksRun.insert("suite2/b2") }

        var runner = BenchmarkRunner(
            suites: [suite1, suite2],
            reporter: BlackHoleReporter(),
            iterations: 1)

        runner.run(options: options)
        return benchmarksRun
    }

    struct BlackHoleReporter: BenchmarkReporter {
        func report(running name: String, suite: String) {}
        func report(results: [BenchmarkResult]) {}
    }
}
