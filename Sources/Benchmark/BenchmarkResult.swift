public struct BenchmarkResult {
    public let benchmarkName: String
    public let measurements: [Double]

    public init(name: String, measurements: [Double]) {
        self.benchmarkName = name
        self.measurements = measurements
    }
}
