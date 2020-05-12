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

    func assertNumberOfIterations(suite: BenchmarkSuite, counts expected: [Int]) throws {
        let options = try BenchmarkCommand(filter: ".*")
        var reporter = BlackHoleReporter()
        var runner = BenchmarkRunner(suites: [suite], reporter: reporter)
        runner.run(command: options)

        XCTAssertEqual(runner.results.count, expected.count)
        let counts = Array(runner.results.map(\.measurements.count))
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
        let suite = BenchmarkSuite(name: "Test", settings: .iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b") {}
        }
        try assertNumberOfIterations(suite: suite, counts: [42, 42])
    }

    func testBenchmarkSetting() throws {
        let suite = BenchmarkSuite(name: "Test") { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: .iterations(42)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [100000, 42])
    }

    func testBenchmarkSettingOverridesSuiteSetting() throws {
        let suite = BenchmarkSuite(name: "Test", settings: .iterations(42)) { suite in
            suite.benchmark("a") {}
            suite.benchmark("b", settings: .iterations(21)) {}
        }
        try assertNumberOfIterations(suite: suite, counts: [42, 21])
    }

    static var allTests = [
        ("testDefaultSetting", testDefaultSetting),
        ("testSuiteSetting", testSuiteSetting),
        ("testBenchmarkSetting", testBenchmarkSetting),
        ("testBenchmarkSettingOverridesSuiteSetting", testBenchmarkSettingOverridesSuiteSetting),
    ]
}
