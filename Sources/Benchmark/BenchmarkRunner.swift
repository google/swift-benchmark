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
    let customDefaults: [BenchmarkSetting]
    var progress: ProgressReporter
    var reporter: BenchmarkReporter

    /// Settings used and measurements taken.
    public var results: [BenchmarkResult] = []

    public init(
        suites: [BenchmarkSuite],
        settings: [BenchmarkSetting],
        customDefaults: [BenchmarkSetting] = []
    ) {
        self.suites = suites
        self.settings = settings
        self.customDefaults = customDefaults
        let globalSettings = BenchmarkSettings([
            defaultSettings,
            self.customDefaults,
            self.settings,
        ])
        if globalSettings.quiet {
            self.progress = QuietReporter()
        } else {
            self.progress = VerboseProgressReporter(output: StderrOutputStream())
        }
        switch globalSettings.format {
        case .none:
            self.reporter = QuietReporter()
        case .console:
            self.reporter = ConsoleReporter(output: StdoutOutputStream())
        case .csv:
            self.reporter = CSVReporter(output: StdoutOutputStream())
        case .json:
            self.reporter = JSONReporter(output: StdoutOutputStream())
        }
    }

    /// Executes each suite in `self.suites` and reports results.
    public mutating func run() throws {
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
            self.customDefaults,
            suite.settings,
            benchmark.settings,
            self.settings,
        ])

        let filter = try BenchmarkFilter(settings.filter, negate: false)
        if !filter.matches(suiteName: suite.name, benchmarkName: benchmark.name) {
            return
        }

        let filterNot = try BenchmarkFilter(settings.filterNot, negate: true)
        if !filterNot.matches(suiteName: suite.name, benchmarkName: benchmark.name) {
            return
        }

        progress.report(running: benchmark.name, suite: suite.name)
        let totalStart = now()

        var warmupState: BenchmarkState? = nil
        if settings.warmupIterations > 0 {
            warmupState = doNIterations(
                settings.warmupIterations, benchmark: benchmark, suite: suite, settings: settings)
        }

        var state: BenchmarkState
        if let n = settings.iterations {
            state = doNIterations(n, benchmark: benchmark, suite: suite, settings: settings)
        } else {
            state = doAdaptiveIterations(
                benchmark: benchmark, suite: suite, settings: settings)
        }

        let totalEnd = now()
        let totalElapsed = totalEnd - totalStart

        progress.report(
            finishedRunning: benchmark.name, suite: suite.name, nanosTaken: totalElapsed)

        let result = BenchmarkResult(
            benchmarkName: benchmark.name,
            suiteName: suite.name,
            settings: settings,
            measurements: state.measurements,
            warmupMeasurements: warmupState != nil ? warmupState!.measurements : [],
            counters: state.counters)
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
    ) -> BenchmarkState {
        var n: Int = 1
        var state: BenchmarkState = BenchmarkState()

        while true {
            state = doNIterations(n, benchmark: benchmark, suite: suite, settings: settings)
            if n != 1 && hasCollectedEnoughData(state.measurements, settings: settings) { break }
            n = predictNumberOfIterationsNeeded(state.measurements, settings: settings)
            assert(
                n > state.measurements.count,
                "Number of iterations should increase with every retry.")
        }

        return state
    }

    func doNIterations(
        _ n: Int, benchmark: AnyBenchmark, suite: BenchmarkSuite, settings: BenchmarkSettings
    ) -> BenchmarkState {
        var state = BenchmarkState(iterations: n, settings: settings)
        do {
            try state.loop(benchmark)
        } catch is BenchmarkTermination {
        } catch {
            fatalError("Unexpected error: \(error).")
        }
        return state
    }
}
