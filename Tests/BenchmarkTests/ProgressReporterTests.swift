// Copyright 2022 Google LLC
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

final class ProgressReporterTests: XCTestCase {

    fileprivate var dummySuite: BenchmarkSuite {
        BenchmarkSuite(name: "SomeSuite") { suite in
            suite.benchmark("SomeBenchmark") { /* No-op */  }
            suite.benchmark("AnotherBenchmark") { /* No-op */  }
        }
    }

    open class DummyProgressReporterBase: ProgressReporter {
        var didReportWillBegin = false
        var didReportWarmingUp = false
        var didReportFinishedWarmup = false
        var didReportRunning = false
        var didReportFinishedRunning = false
        var benchmarksFinished = 0

        init() {}

        private func resetCallbackFlags() {
            didReportWillBegin = false
            didReportWarmingUp = false
            didReportFinishedWarmup = false
            didReportRunning = false
            didReportFinishedRunning = false
        }

        open func reportWillBeginBenchmark(_ benchmark: AnyBenchmark, suite: BenchmarkSuite) {
            resetCallbackFlags()
            didReportWillBegin = true
        }

        open func reportFinishedBenchmark(nanosTaken: UInt64) {
            resetCallbackFlags()
            benchmarksFinished += 1
        }

        open func reportWarmingUp() {
            didReportWarmingUp = true
        }

        open func reportFinishedWarmup(nanosTaken: UInt64) {
            didReportFinishedWarmup = true
        }

        open func reportRunning() {
            didReportRunning = true
        }

        open func reportFinishedRunning(nanosTaken: UInt64) {
            didReportFinishedRunning = true
        }
    }

    func testProgressReportNoWarmup() throws {

        class Reporter: DummyProgressReporterBase {
            var remainingBenchmarks = ["SomeBenchmark", "AnotherBenchmark"]

            override func reportWillBeginBenchmark(
                _ benchmark: AnyBenchmark, suite: BenchmarkSuite
            ) {
                super.reportWillBeginBenchmark(benchmark, suite: suite)
                XCTAssertEqual(benchmark.name, remainingBenchmarks.removeFirst())
                XCTAssertEqual(suite.name, "SomeSuite")
            }
            override func reportFinishedBenchmark(nanosTaken: UInt64) {
                XCTAssertTrue(didReportWillBegin)
                XCTAssertFalse(didReportWarmingUp)
                XCTAssertFalse(didReportFinishedWarmup)
                XCTAssertTrue(didReportRunning)
                XCTAssertTrue(didReportFinishedRunning)
                super.reportFinishedBenchmark(nanosTaken: nanosTaken)
            }
        }

        let reporter = Reporter()
        var runner = BenchmarkRunner(suites: [dummySuite], settings: [Iterations(5)])
        runner.progress = reporter
        try runner.run()
        XCTAssertEqual(reporter.remainingBenchmarks, [])
        XCTAssertEqual(reporter.benchmarksFinished, 2)
    }

    func testProgressReportWithWarmup() throws {

        class Reporter: DummyProgressReporterBase {
            var remainingBenchmarks = ["SomeBenchmark", "AnotherBenchmark"]

            override func reportWillBeginBenchmark(
                _ benchmark: AnyBenchmark, suite: BenchmarkSuite
            ) {
                super.reportWillBeginBenchmark(benchmark, suite: suite)
                XCTAssertEqual(benchmark.name, remainingBenchmarks.removeFirst())
                XCTAssertEqual(suite.name, "SomeSuite")
            }
            override func reportFinishedBenchmark(nanosTaken: UInt64) {
                XCTAssertTrue(didReportWillBegin)
                XCTAssertTrue(didReportWarmingUp)
                XCTAssertTrue(didReportFinishedWarmup)
                XCTAssertTrue(didReportRunning)
                XCTAssertTrue(didReportFinishedRunning)
                super.reportFinishedBenchmark(nanosTaken: nanosTaken)
            }
        }

        let reporter = Reporter()
        var runner = BenchmarkRunner(
            suites: [dummySuite], settings: [WarmupIterations(42), Iterations(5)]
        )
        runner.progress = reporter
        try runner.run()
        XCTAssertEqual(reporter.remainingBenchmarks, [])
        XCTAssertEqual(reporter.benchmarksFinished, 2)
    }

    static var allTests = [
        ("testProgressReportNoWarmup", testProgressReportNoWarmup),
        ("testProgressReportWithWarmup", testProgressReportWithWarmup),
    ]
}
