public struct BenchmarkResult {
    public let benchmarkName: String
    public let suiteName: String
    public let measurements: [Double]

    public init(benchmarkName: String, suiteName: String, measurements: [Double]) {
        self.benchmarkName = benchmarkName
        self.suiteName = suiteName
        self.measurements = measurements
    }
}
