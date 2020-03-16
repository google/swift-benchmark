public protocol Benchmark {
    func run()
}

private class ClosureBenchmark: Benchmark {
    let closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    func run() {
        self.closure()
    }
}

public func benchmark(name: String, f: @escaping () -> Void) throws {
    let benchmark = ClosureBenchmark(f)
    try defaultBenchmarkRegistry.register(name: name, benchmark: benchmark)
}
