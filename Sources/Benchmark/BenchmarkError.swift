struct BenchmarkError: Error {
    let reason: String

    init(reason: String) {
        self.reason = reason
    }
}
