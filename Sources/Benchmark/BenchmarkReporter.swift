protocol BenchmarkReporter {
    func report(results: [BenchmarkResult])
}

struct PlainTextReporter: BenchmarkReporter {
    func report(results: [BenchmarkResult]) {
        for result in results {
            print("result \(result.benchmarkName) is \(result.elapsedTime) ns")
        }
    }
}
