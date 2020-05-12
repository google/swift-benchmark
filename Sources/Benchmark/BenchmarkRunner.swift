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
    let reporter: BenchmarkReporter
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
        let settings = try BenchmarkSettings([
            defaultSettings, 
            self.settings, 
            suite.settings, 
            benchmark.settings
        ])

        if !settings.filter.matches(suiteName: suite.name, benchmarkName: benchmark.name) {
            return
        }

        reporter.report(running: benchmark.name, suite: suite.name)

        var clock = BenchmarkClock()
        var measurements: [Double] = []
        measurements.reserveCapacity(settings.iterations)

        if settings.warmupIterations > 0 {
            for _ in 1...settings.warmupIterations {
                benchmark.run()
            }
        }

        for _ in 1...settings.iterations {
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
