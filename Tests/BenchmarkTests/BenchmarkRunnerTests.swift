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
        XCTAssertEqual(Set(["suite1.b1", "suite2.b1"]), runBenchmarks(settings: settings))
    }

    func testFilterBenchmarksSuiteName() throws {
        let settings: [BenchmarkSetting] = [Iterations(1), Filter("suite1")]
        XCTAssertEqual(Set(["suite1.b1", "suite1.b2"]), runBenchmarks(settings: settings))
    }

    func testFilterBenchmarksFullName() throws {
        let settings: [BenchmarkSetting] = [Iterations(1), Filter("suite1.b1")]
        XCTAssertEqual(Set(["suite1.b1"]), runBenchmarks(settings: settings))
    }

    func testAutomaticallyDetectIterations() throws {
        let settings: [BenchmarkSetting] = []
        XCTAssertEqual(
            Set(["suite2.b2", "suite2.b1", "suite1.b2", "suite1.b1"]),
            runBenchmarks(settings: settings))
    }

    func testWarmupMeasurements() throws {
        let suite = BenchmarkSuite(name: "Suite")

        suite.benchmark("no warmup") {
        }
        suite.benchmark("needs warmup", settings: WarmupIterations(10)) {
        }

        let results = try run(suites: [suite], settings: [Iterations(100)])
        XCTAssertEqual(results.count, 2)

        let counts = results.map { $0.warmupMeasurements.count }
        XCTAssertEqual(counts, [0, 10])
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

        let results = try run(suites: [suite], settings: [Iterations(100)])
        XCTAssertEqual(results.count, 5)

        let counts = results.map { $0.measurements.count }
        XCTAssertEqual(counts, [100, 100, 100, 100, 100])
    }

    func testCustomCounters() throws {
        let suite = BenchmarkSuite(name: "Suite")

        suite.benchmark("counter increment") { state in
            state.increment(counter: "n")
        }
        suite.benchmark("counter increment by 10") { state in
            state.increment(counter: "n", by: 10)
        }
        suite.benchmark("counter set") { state in
            state.counters["n"] = 42
        }

        let results = try run(suites: [suite], settings: [Iterations(100)])
        XCTAssertEqual(results.count, 3)

        let values = Array(results.map { $0.counters["n"] })
        XCTAssertEqual(values, [100, 1000, 42])
    }

    static var allTests = [
        ("testFilterBenchmarksSuffix", testFilterBenchmarksSuffix),
        ("testFilterBenchmarksSuiteName", testFilterBenchmarksSuiteName),
        ("testFilterBenchmarksFullName", testFilterBenchmarksFullName),
        ("testAutomaticallyDetectIterations", testAutomaticallyDetectIterations),
        ("testWarmupMeasurements", testWarmupMeasurements),
        ("testCustomMeasurements", testCustomMeasurements),
        ("testCustomCounters", testCustomCounters),
    ]
}

extension BenchmarkRunnerTests {
    func run(suites: [BenchmarkSuite], settings: [BenchmarkSetting]) throws -> [BenchmarkResult] {
        var allSettings: [BenchmarkSetting] = [Format(.none), Quiet(true)]
        allSettings.append(contentsOf: settings)
        var runner = BenchmarkRunner(
            suites: suites,
            settings: allSettings)
        try runner.run()
        return runner.results
    }

    /// Builds and runs a few suites of benchmarks with provided settings; returns the set of
    /// benchmark names that were run.
    func runBenchmarks(settings: [BenchmarkSetting]) -> Set<String> {
        let suite1 = BenchmarkSuite(name: "suite1")
        let suite2 = BenchmarkSuite(name: "suite2")

        var benchmarksRun = Set<String>()

        suite1.benchmark("b1") { benchmarksRun.insert("suite1.b1") }
        suite2.benchmark("b1") { benchmarksRun.insert("suite2.b1") }
        suite1.benchmark("b2") { benchmarksRun.insert("suite1.b2") }
        suite2.benchmark("b2") { benchmarksRun.insert("suite2.b2") }

        do {
            let _ = try run(suites: [suite1, suite2], settings: settings)
            return benchmarksRun
        } catch {
            return Set<String>()
        }
    }
}
