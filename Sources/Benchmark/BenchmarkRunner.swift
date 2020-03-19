public struct BenchmarkRunner {
    let registry: BenchmarkRegistry
    let reporter: BenchmarkReporter
    let runs: Int
    let iterationTimeout: Int
    var results: [BenchmarkResult] = []
    var outputs: [Any] = []

    init(
        registry: BenchmarkRegistry, reporter: BenchmarkReporter,
        runs: Int, iterationTimeout: Int
    ) {
        self.registry = registry
        self.reporter = reporter
        self.runs = runs
        self.iterationTimeout = iterationTimeout
    }

    mutating func run() {
        var clock = BenchmarkClock()
        let n = registry.benchmarks.count
        results = []
        results.reserveCapacity(n)
        outputs = []
        outputs.reserveCapacity(n)

        for (benchmarkName, benchmark) in registry.benchmarks {
            for run in 1...runs {
                reporter.report(running: benchmarkName, run: run)

                var iterations: UInt64 = 0
                var elapsed: UInt64 = 0
                clock.recordStart()
                while elapsed < iterationTimeout {
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
        reporter: PlainTextReporter(),
        runs: 10,
        iterationTimeout: 1_000_000_000)
    runner.run()
}
