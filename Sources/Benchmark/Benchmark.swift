public protocol AnyBenchmark {
    func run() -> Any
}

private class ClosureBenchmark: AnyBenchmark {
    let closure: () -> Any

    init(_ closure: @escaping () -> Any) {
        self.closure = closure
    }

    func run() -> Any {
        return self.closure()
    }
}

public func benchmark(_ name: String, f: @escaping () -> Any) {
    let benchmark = ClosureBenchmark(f)
    defaultBenchmarkRegistry.register(name: name, benchmark: benchmark)
}
