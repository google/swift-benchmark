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
        let settings: [BenchmarkSetting] = [Iterations(1), Filter("b1")]
        XCTAssertEqual(Set(["suite1/b1", "suite2/b1"]), runBenchmarks(settings: settings))
    }

    func testFilterBenchmarksSuiteName() throws {
        let settings: [BenchmarkSetting] = [Iterations(1), Filter("suite1")]
        XCTAssertEqual(Set(["suite1/b1", "suite1/b2"]), runBenchmarks(settings: settings))
    }

    func testFilterBenchmarksFullName() throws {
        let settings: [BenchmarkSetting] = [Iterations(1), Filter("suite1/b1")]
        XCTAssertEqual(Set(["suite1/b1"]), runBenchmarks(settings: settings))
    }

    func testAutomaticallyDetectIterations() throws {
        let settings: [BenchmarkSetting] = []
        XCTAssertEqual(
            Set(["suite2/b2", "suite2/b1", "suite1/b2", "suite1/b1"]),
            runBenchmarks(settings: settings))
    }

    func testCustomMeasurements() throws {
        let suite = BenchmarkSuite(name: "Suite")

        suite.benchmark("noop") {
        }

        suite.benchmark("start/end noop") { state in
            state.start()
            try state.end()
        }

        suite.benchmark("measure noop") { state in
            try state.measure {
            }
        }

        suite.benchmark("measure/while noop") { state in
            while true {
                try state.measure {
                }
            }
        }

        suite.benchmark("measure uneven iterations noop") { state in
            for _ in 1...1337 {
                try state.measure {
                }
            }
        }

        var runner = BenchmarkRunner(
            suites: [suite],
            settings: [Iterations(100000)],
            reporter: BlackHoleReporter())
        try runner.run()

        let noopResults = runner.results[0].measurements
        let customResults = runner.results.map { $0.measurements }.dropFirst()

        XCTAssertEqual(noopResults.count, 100000)
        for customResult in customResults {
            XCTAssertEqual(customResult.count, 100000)
        }
    }

    static var allTests = [
        ("testFilterBenchmarksSuffix", testFilterBenchmarksSuffix),
        ("testFilterBenchmarksSuiteName", testFilterBenchmarksSuiteName),
        ("testFilterBenchmarksFullName", testFilterBenchmarksFullName),
        ("testAutomaticallyDetectIterations", testAutomaticallyDetectIterations),
        ("testCustomMeasurements", testCustomMeasurements),
    ]
}

extension BenchmarkRunnerTests {
    /// Builds and runs a few suites of benchmarks with provided settings; returns the set of
    /// benchmark names that were run.
    func runBenchmarks(settings: [BenchmarkSetting]) -> Set<String> {
        let suite1 = BenchmarkSuite(name: "suite1")
        let suite2 = BenchmarkSuite(name: "suite2")

        var benchmarksRun = Set<String>()

        suite1.benchmark("b1") { benchmarksRun.insert("suite1/b1") }
        suite2.benchmark("b1") { benchmarksRun.insert("suite2/b1") }
        suite1.benchmark("b2") { benchmarksRun.insert("suite1/b2") }
        suite2.benchmark("b2") { benchmarksRun.insert("suite2/b2") }

        var runner = BenchmarkRunner(
            suites: [suite1, suite2],
            settings: settings,
            reporter: BlackHoleReporter())

        do {
            try runner.run()
            return benchmarksRun
        } catch {
            return Set<String>()
        }
    }
}
