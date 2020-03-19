public struct BenchmarkRunner {
    let registry: BenchmarkRegistry
    let reporter: BenchmarkReporter
    let iterations: Int

    init(
        registry: BenchmarkRegistry, reporter: BenchmarkReporter,
        iterations: Int
    ) {
        self.registry = registry
        self.reporter = reporter
        self.iterations = iterations
    }

    mutating func run() {
        var results: [BenchmarkResult] = []
        results.reserveCapacity(registry.benchmarks.count)

        for (benchmarkName, benchmark) in registry.benchmarks {
            reporter.report(running: benchmarkName)

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
                name: benchmarkName,
                measurements: measurements)
            results.append(result)
        }

        reporter.report(results: results)
    }
}

public func main() {
    var runner = BenchmarkRunner(
        registry: defaultBenchmarkRegistry,
        reporter: PlainTextReporter(),
        iterations: 10000)
    runner.run()
}
