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

final class CustomBenchmarkTests: XCTestCase {
    func testSetUpAndTearDown() throws {
        let benchmark = MockBenchmark()

        let suite = BenchmarkSuite(name: "suite")
        suite.benchmarks = [benchmark]

        var runner = BenchmarkRunner(suites: [suite], settings: [Format(.none), Quiet(true)])

        try runner.run()

        XCTAssertTrue(benchmark.didSetUp)
        XCTAssertTrue(benchmark.didRun)
        XCTAssertTrue(benchmark.didTearDown)
    }

    static var allTests = [
        ("testSetUpAndTearDown", testSetUpAndTearDown)
    ]
}

fileprivate class MockBenchmark: AnyBenchmark {
    let name = "Custom"

    var settings: [BenchmarkSetting] = []

    var didSetUp: Bool = false
    var didRun: Bool = false
    var didTearDown: Bool = false

    func setUp() {
        didSetUp = true
    }

    func run(_ state: inout BenchmarkState) {
        didRun = true
    }

    func tearDown() {
        didTearDown = true
    }
}
