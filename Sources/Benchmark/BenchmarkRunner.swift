public struct BenchmarkRunner {
    let registry: BenchmarkRegistry
    let reporter: BenchmarkReporter
    var results: [BenchmarkResult] = []
    var outputs: [Any] = []

    init(registry: BenchmarkRegistry, reporter: BenchmarkReporter) {
        self.registry = registry
        self.reporter = reporter
    }

    mutating func run() {
        var clock = BenchmarkClock()
        let n = registry.benchmarks.count
        results = []
        results.reserveCapacity(n)
        outputs = []
        outputs.reserveCapacity(n)

        for (benchmarkName, benchmark) in registry.benchmarks {
            for run in 1...10 {
                reporter.report(running: benchmarkName, run: run)

                var iterations: UInt64 = 0
                var elapsed: UInt64 = 0
                clock.recordStart()
                while elapsed < 1_000_000_000 {
                    iterations += 1
                    let output = benchmark.run()
                    clock.recordEnd()
                    elapsed = clock.elapsed
                    outputs.append(output)
                }
                let result = BenchmarkResult(
                    name: benchmarkName,
                    elapsed: clock.elapsed,
                    iterations: iterations,
                    run: run)
                results.append(result)
            }
        }

        reporter.report(results: results)
    }
}

public func main() {
    var runner = BenchmarkRunner(
        registry: defaultBenchmarkRegistry,
        reporter: PlainTextReporter())
    runner.run()
}
