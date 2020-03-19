import Benchmark

benchmark("add string no capacity") {
    var x1: String = ""
    for _ in 1...1000 {
        x1 += "hi"
    }
}

benchmark("add string reserved capacity") {
    var x2: String = ""
    x2.reserveCapacity(2000)
    for _ in 1...1000 {
        x2 += "hi"
    }
}

Benchmark.main()
