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
        cli: [BenchmarkSetting],
        customDefaults: [BenchmarkSetting] = []
    ) throws {
        var settings: [BenchmarkSetting] = [Format(.none), Quiet(true)]
        settings.append(contentsOf: cli)
        var runner = BenchmarkRunner(
            suites: [suite], settings: settings, customDefaults: customDefaults)

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
        try assertNumberOfIterations(
            suite: suite,
            counts: [1_000_000, 1_000_000],
            cli: [])
    }

    func testSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [42, 42],
            cli: [])
    }

    func testBenchmarkSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(42)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1_000_000, 42],
            cli: [])
    }

    func testBenchmarkSettingOverridesSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(21)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [42, 21],
            cli: [])
    }

    func testCliSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1, 1],
            cli: [Iterations(1)])
    }

    func testCliOverridesSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(2)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1, 1],
            cli: [Iterations(1)])
    }

    func testCliOverridesBenchmarkSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(2)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1, 1],
            cli: [Iterations(1)])
    }

    func testCliOverridesBenchmarkAndSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(2)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(3)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1, 1],
            cli: [Iterations(1)])
    }

    func testCustomDefaults() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [1, 1],
            cli: [],
            customDefaults: [Iterations(1)])
    }

    func testCustomDafaultsOverridenBySuite() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(3)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [3, 3],
            cli: [],
            customDefaults: [Iterations(1)])
    }

    func testCustomDafaultsOverridenByBenchmark() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(3)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(4)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [3, 4],
            cli: [],
            customDefaults: [Iterations(1)])
    }

    func testCustomDafaultsOverridenByCli() throws {
        let suite = BenchmarkSuite(name: "Test", settings: Iterations(3)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: Iterations(4)) {}
        }
        try assertNumberOfIterations(
            suite: suite,
            counts: [5, 5],
            cli: [Iterations(5)],
            customDefaults: [Iterations(1)])
    }

    static var allTests = [
        ("testDefaultSetting", testDefaultSetting),
        ("testSuiteSetting", testSuiteSetting),
        ("testBenchmarkSetting", testBenchmarkSetting),
        ("testBenchmarkSettingOverridesSuiteSetting", testBenchmarkSettingOverridesSuiteSetting),
        ("testCliSetting", testCliSetting),
        ("testCliOverridesSuiteSetting", testCliOverridesSuiteSetting),
        ("testCliOverridesBenchmarkSetting", testCliOverridesBenchmarkSetting),
        ("testCliOverridesBenchmarkAndSuiteSetting", testCliOverridesBenchmarkAndSuiteSetting),
        ("testCustomDefaults", testCustomDefaults),
        ("testCustomDafaultsOverridenBySuite", testCustomDafaultsOverridenBySuite),
        ("testCustomDafaultsOverridenByBenchmark", testCustomDafaultsOverridenByBenchmark),
        ("testCustomDafaultsOverridenByCli", testCustomDafaultsOverridenByCli),
    ]
}
