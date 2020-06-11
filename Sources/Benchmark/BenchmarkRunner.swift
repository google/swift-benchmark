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

public struct BenchmarkRunner {
    let suites: [BenchmarkSuite]
    let settings: [BenchmarkSetting]
    var reporter: BenchmarkReporter
    var results: [BenchmarkResult] = []

    init(suites: [BenchmarkSuite], settings: [BenchmarkSetting], reporter: BenchmarkReporter) {
        self.suites = suites
        self.settings = settings
        self.reporter = reporter
    }

    mutating func run() throws {
        for suite in suites {
            try run(suite: suite)
        }
        reporter.report(results: results)
    }

    mutating func run(suite: BenchmarkSuite) throws {
        for benchmark in suite.benchmarks {
            try run(benchmark: benchmark, suite: suite)
        }
    }

    mutating func run(benchmark: AnyBenchmark, suite: BenchmarkSuite) throws {
        let settings = BenchmarkSettings([
            defaultSettings,
            self.settings,
            suite.settings,
            benchmark.settings,
        ])

        let filter = try BenchmarkFilter(settings.filter)
        if !filter.matches(suiteName: suite.name, benchmarkName: benchmark.name) {
            return
        }

        reporter.report(running: benchmark.name, suite: suite.name)
        var totalTime = BenchmarkClock()
        totalTime.recordStart()

        if let n = settings.warmupIterations {
            let _ = doNIterations(n, benchmark: benchmark, suite: suite)
        }

        var measurements: [Double] = []
        if let n = settings.iterations {
            measurements = doNIterations(n, benchmark: benchmark, suite: suite)
        } else {
            measurements = doAdaptiveIterations(
                benchmark: benchmark, suite: suite, settings: settings)
        }

        totalTime.recordEnd()
        reporter.report(
            finishedRunning: benchmark.name, suite: suite.name, nanosTaken: totalTime.elapsed)

        let result = BenchmarkResult(
            benchmarkName: benchmark.name,
            suiteName: suite.name,
            measurements: measurements)
        results.append(result)
    }

    /// Heuristic for finding good next number of iterations to try, ported from google/benchmark.
    func predictNumberOfIterationsNeeded(_ measurements: [Double], settings: BenchmarkSettings)
        -> Int
    {
        let minTime = settings.minTime
        let iters = measurements.count

        // See how much iterations should be increased by.
        // Note: Avoid division by zero with max(timeInSeconds, 1ns)
        let timeInSeconds = measurements.reduce(0, +) / 1000000000.0
        var multiplier: Double = minTime * 1.4 / max(timeInSeconds, 1e-9)

        // If our last run was at least 10% of --min-time then we
        // use the multiplier directly.
        // Otherwise we use at most 10 times expansion.
        // NOTE: When the last run was at least 10% of the min time the max
        // expansion should be 14x.
        let isSignificant = (timeInSeconds / minTime) > 0.1
        multiplier = isSignificant ? multiplier : min(10.0, multiplier)
        if multiplier < 1.0 {
            multiplier = 2.0
        }

        // So what seems to be the sufficiently-large iteration count? Round up.
        let maxNextIters: Int = Int(max(multiplier * Double(iters), Double(iters) + 1.0).rounded())

        // But we do have *some* sanity limits though..
        let nextIters = min(maxNextIters, settings.maxIterations)

        return nextIters
    }

    /// Heuristic when to stop looking for new number of iterations, ported from google/benchmark.
    func hasCollectedEnoughData(_ measurements: [Double], settings: BenchmarkSettings) -> Bool {
        let tooManyIterations = measurements.count >= settings.maxIterations
        let timeInSeconds = measurements.reduce(0, +) / 1000000000.0
        let timeIsLargeEnough = timeInSeconds >= settings.minTime
        return tooManyIterations || timeIsLargeEnough
    }

    func doAdaptiveIterations(
        benchmark: AnyBenchmark, suite: BenchmarkSuite, settings: BenchmarkSettings
    ) -> [Double] {
        var measurements: [Double] = []
        var n: Int = 1

        while true {
            measurements = doNIterations(n, benchmark: benchmark, suite: suite)
            if n != 1 && hasCollectedEnoughData(measurements, settings: settings) { break }
            n = predictNumberOfIterationsNeeded(measurements, settings: settings)
            assert(n > measurements.count, "Number of iterations should increase with every retry.")
        }

        return measurements
    }

    func doNIterations(_ n: Int, benchmark: AnyBenchmark, suite: BenchmarkSuite) -> [Double] {
        var clock = BenchmarkClock()
        var measurements: [Double] = []
        measurements.reserveCapacity(n)

        for _ in 1...n {
            benchmark.setUp()
            clock.recordStart()
            benchmark.run()
            clock.recordEnd()
            benchmark.tearDown()
            measurements.append(Double(clock.elapsed))
        }

        return measurements
    }
}
