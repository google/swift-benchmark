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

    mutating func run() {
        for suite in suites {
            run(suite: suite)
        }
        reporter.report(results: results)
    }

    mutating func run(suite: BenchmarkSuite) {
        for benchmark in suite.benchmarks {
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
