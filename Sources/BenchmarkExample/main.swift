import Benchmark

benchmark("add string no capacity") {
    var x: String = ""
    for _ in 1...1000 {
        x += "hi"
    }
    return x
}

benchmark("add string reserved capacity") {
    var x: String = ""
    x.reserveCapacity(1000)
    for _ in 1...1000 {
        x += "hi"
    }
    return x
}

Benchmark.main()
