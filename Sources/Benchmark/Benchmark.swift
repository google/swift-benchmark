public protocol AnyBenchmark {
    func run()
}

private class ClosureBenchmark: AnyBenchmark {
    let closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    func run() {
        return self.closure()
    }
}

public func benchmark(_ name: String, f: @escaping () -> Void) {
    let benchmark = ClosureBenchmark(f)
    defaultBenchmarkRegistry.register(name: name, benchmark: benchmark)
}
