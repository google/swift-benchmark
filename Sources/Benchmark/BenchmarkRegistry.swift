public struct BenchmarkRegistry {
    public var benchmarks: [String: Benchmark] = [:]

    public mutating func register(name: String, benchmark: Benchmark) throws {
        if benchmarks[name] != nil {
            throw BenchmarkError(
                reason: "benchmark with name `\(name)` already exists in the registry")
        } else {
            benchmarks[name] = benchmark
        }
    }

    public mutating func clear() {
        self.benchmarks = [:]
    }
}

var defaultBenchmarkRegistry = BenchmarkRegistry()
