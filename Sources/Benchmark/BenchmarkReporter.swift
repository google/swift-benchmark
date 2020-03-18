protocol BenchmarkReporter {
    func report(results: [BenchmarkResult])
}

struct PlainTextReporter: BenchmarkReporter {
    func report(results: [BenchmarkResult]) {
        for result in results {
            let time = Double(result.elapsedTime) / Double(result.iterations)
            print("result \(result.benchmarkName) is \(time) ns / iteration")
        }
    }
}
