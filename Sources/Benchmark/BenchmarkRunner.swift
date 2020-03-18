public struct BenchmarkRunner {
    let registry: BenchmarkRegistry
    var results: [BenchmarkResult] = []
    var outputs: [Any] = []

    init(_ registry: BenchmarkRegistry) {
        self.registry = registry
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
    }
}

public func main() {
    var runner = BenchmarkRunner(defaultBenchmarkRegistry)
    runner.run()
    let reporter = PlainTextReporter()
    reporter.report(results: runner.results)
}
