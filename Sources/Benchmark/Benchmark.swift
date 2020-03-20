public protocol AnyBenchmark {
    var name: String { get }
    func run()
}

internal class ClosureBenchmark: AnyBenchmark {
    let name: String
    let closure: () -> Void

    init(_ name: String, _ closure: @escaping () -> Void) {
        self.name = name
        self.closure = closure
    }

    func run() {
        return self.closure()
    }
}

public func benchmark(_ name: String, f: @escaping () -> Void) {
    defaultBenchmarkSuite.benchmark(name, f)
}
