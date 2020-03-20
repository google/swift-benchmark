import Benchmark

let addStringBenchmarks = BenchmarkSuite(name: "add string") { suite in
    suite.benchmark("no capacity") {
        var x1: String = ""
        for _ in 1...1000 {
            x1 += "hi"
        }
    }

    suite.benchmark("reserved capacity") {
        var x2: String = ""
        x2.reserveCapacity(2000)
        for _ in 1...1000 {
            x2 += "hi"
        }
    }
}
