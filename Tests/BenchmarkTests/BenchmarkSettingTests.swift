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

final class BenchmarkSettingTests: XCTestCase {

    func assertNumberOfIterations(
        suite: BenchmarkSuite,
        counts expected: [Int],
        cli settings: [BenchmarkSetting] = [Iterations(100000)]
    ) throws {
        var runner = BenchmarkRunner(
            suites: [suite], settings: settings, reporter: BlackHoleReporter())

        try runner.run()
        XCTAssertEqual(runner.results.count, expected.count)
        let counts = Array(
            runner.results.map { result in
                result.measurements.count
            })
        XCTAssertEqual(counts, expected)
    }

    func testDefaultSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(suite: suite, counts: [100000, 100000])
    }

    func testSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(suite: suite, counts: [42, 42])
    }

    func testBenchmarkSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(42)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [100000, 42])
    }

    func testBenchmarkSettingOverridesSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(21)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [42, 21])
    }

    func testCliSetting() throws {
        let cli: [BenchmarkSetting] = [Iterations(1)]
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(suite: suite, counts: [1, 1], cli: cli)
    }

    func testSuiteOverridesCliSetting() throws {
        let cli: [BenchmarkSetting] = [Iterations(1)]
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(2)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(suite: suite, counts: [2, 2], cli: cli)
    }

    func testBenchmarkOverridesCliSetting() throws {
        let cli: [BenchmarkSetting] = [Iterations(1)]
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(2)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [1, 2], cli: cli)
    }

    func testBenchmarkAndSuiteOverridesCliSetting() throws {
        let cli: [BenchmarkSetting] = [Iterations(1)]
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(2)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(3)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [2, 3], cli: cli)
    }

    static var allTests = [
        ("testDefaultSetting", testDefaultSetting),
        ("testSuiteSetting", testSuiteSetting),
        ("testBenchmarkSetting", testBenchmarkSetting),
        ("testBenchmarkSettingOverridesSuiteSetting", testBenchmarkSettingOverridesSuiteSetting),
        ("testCliSetting", testCliSetting),
        ("testSuiteOverridesCliSetting", testSuiteOverridesCliSetting),
        ("testBenchmarkOverridesCliSetting", testBenchmarkOverridesCliSetting),
        ("testBenchmarkAndSuiteOverridesCliSetting", testBenchmarkAndSuiteOverridesCliSetting),
    ]
}
