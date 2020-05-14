import Foundation

struct BenchmarkReport: Encodable {
    struct Context: Encodable {
        let date: Date = Date()
    }

    let context: Context
    let results: [BenchmarkResult]

    init(results: [BenchmarkResult]) {
        self.context = Context()
        self.results = results
    }
}
