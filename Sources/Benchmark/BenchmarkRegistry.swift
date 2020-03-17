public struct BenchmarkRegistry {
    public var benchmarks: [String: AnyBenchmark] = [:]

    public mutating func register(name: String, benchmark: AnyBenchmark) {
        if benchmarks[name] != nil {
            fatalError("benchmark with name `\(name)` already exists in the registry")
        } else {
            benchmarks[name] = benchmark
        }
    }

    public mutating func clear() {
        self.benchmarks = [:]
    }
}

var defaultBenchmarkRegistry = BenchmarkRegistry()
