public struct BenchmarkRunner {
    let registry: BenchmarkRegistry
    var results: [BenchmarkResult] = []

    init(_ registry: BenchmarkRegistry) {
        self.registry = registry
    }

    mutating func run() {
        var clock = BenchmarkClock()
        var outputs: [Any] = []
        let n = registry.benchmarks.count
        results = []
        results.reserveCapacity(n)
        outputs.reserveCapacity(n)

        for (benchmarkName, benchmark) in registry.benchmarks {
            clock.recordStart()
            let output = benchmark.run()
            clock.recordEnd()
            outputs.append(output)
            let result = BenchmarkResult(
                name: benchmarkName,
                elapsed: clock.elapsed)
            results.append(result)
        }
    }
}

public func main() {
    var runner = BenchmarkRunner(defaultBenchmarkRegistry)
    runner.run()
    let reporter = PlainTextReporter()
    reporter.report(results: runner.results)
}
