public struct BenchmarkResult {
    public let benchmarkName: String
    public let elapsedTime: UInt64
    public let iterations: UInt64
    public let run: Int

    public init(name: String, elapsed time: UInt64, iterations: UInt64, run: Int) {
        self.benchmarkName = name
        self.elapsedTime = time
        self.iterations = iterations
        self.run = run
    }
}
