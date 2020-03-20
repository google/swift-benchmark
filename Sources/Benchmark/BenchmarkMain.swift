public func main(_ suites: [BenchmarkSuite]) {
    var runner = BenchmarkRunner(
        suites: suites,
        reporter: PlainTextReporter(),
        iterations: 10000)
    runner.run()
}

public func main() {
    main([defaultBenchmarkSuite])
}
