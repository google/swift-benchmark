protocol BenchmarkReporter {
    func report(running name: String, run: Int)
    func report(results: [BenchmarkResult])
}

struct PlainTextReporter: BenchmarkReporter {
    func report(running name: String, run: Int) {
        print("running \(name), run #\(run)")
    }

    func report(results: [BenchmarkResult]) {
        for result in results {
            let time = Double(result.elapsedTime) / Double(result.iterations)
            print("result \(result.benchmarkName) is \(time) ns / iteration")
        }
    }
}
