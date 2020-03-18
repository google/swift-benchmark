public struct BenchmarkResult {
    public let benchmarkName: String
    public let elapsedTime: UInt64

    public init(name: String, elapsed time: UInt64) {
        self.benchmarkName = name
        self.elapsedTime = time
    }
}
