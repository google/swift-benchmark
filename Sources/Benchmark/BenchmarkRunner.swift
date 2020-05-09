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

import ArgumentParser
import Foundation

public struct BenchmarkRunner {
    let suites: [BenchmarkSuite]
    let reporter: BenchmarkReporter
    let iterations: Int
    var results: [BenchmarkResult] = []

    init(
        suites: [BenchmarkSuite], reporter: BenchmarkReporter,
        iterations: Int
    ) {
        self.suites = suites
        self.reporter = reporter
        self.iterations = iterations
    }

    mutating func run(options: BenchmarkRunnerOptions) {
        for suite in suites {
            run(suite: suite, options: options)
        }
        reporter.report(results: results)
    }

    mutating func run(suite: BenchmarkSuite, options: BenchmarkRunnerOptions) {
        for benchmark in suite.benchmarks {
            if !options.matches(suiteName: suite.name, benchmarkName: benchmark.name) { continue }
            run(benchmark: benchmark, suite: suite)
        }
    }

    mutating func run(benchmark: AnyBenchmark, suite: BenchmarkSuite) {
        reporter.report(running: benchmark.name, suite: suite.name)

        var clock = BenchmarkClock()
        var measurements: [Double] = []
        measurements.reserveCapacity(iterations)

        for _ in 1...iterations {
            clock.recordStart()
            benchmark.run()
            clock.recordEnd()
            measurements.append(Double(clock.elapsed))
        }

        let result = BenchmarkResult(
            benchmarkName: benchmark.name,
            suiteName: suite.name,
            measurements: measurements)
        results.append(result)
    }
}

/// Allows dynamic configuration of the benchmark execution.
internal struct BenchmarkRunnerOptions: ParsableCommand {
    @Option(
        help: "Run only benchmarks whose names match the regular expression.",
        transform: BenchmarkFilter.init)
    var filter: BenchmarkFilter?

    @Flag(help: "Overrides check to verify optimized build.")
    var allowDebugBuild: Bool

    mutating func validate() throws {
        var isDebug = false
        assert({ isDebug = true; return true }())
        if isDebug && !allowDebugBuild {
            throw ValidationError(debugBuildErrorMessage)
        }
    }

    var debugBuildErrorMessage: String {
            """
Please build with optimizations enabled (`-c release` if using SwiftPM,
`-c opt` if using bazel, or `-O` if using swiftc directly). If you would really
like to run the benchmark without optimizations, pass the `--allow-debug-build`
flag.
"""
    }
}

extension BenchmarkRunnerOptions {
    func matches(suiteName: String, benchmarkName: String) -> Bool {
        guard let filter = filter else { return true }
        return filter.matches(suiteName: suiteName, benchmarkName: benchmarkName)
    }

    init(filter: String) throws {
        self.filter = try BenchmarkFilter(filter)
        self.allowDebugBuild = false
    }
}

internal struct BenchmarkFilter {
    let underlying: NSRegularExpression

    init(_ regularExpression: String) throws {
        underlying = try NSRegularExpression(
            pattern: regularExpression,
            options: [.caseInsensitive, .anchorsMatchLines])
    }

    func matches(suiteName: String, benchmarkName: String) -> Bool {
        let str = "\(suiteName)/\(benchmarkName)"
        let range = NSRange(location: 0, length: str.utf16.count)
        return underlying.firstMatch(in: str, range: range) != nil
    }
}
