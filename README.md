
# swift-benchmark

A swift library to benchmark code snippets, similar to
(google/benchmark)[https://github.com/google/benchmark].  Example:


```
import Benchmark

benchmark("add string reserved capacity") {
    var x2: String = ""
    x2.reserveCapacity(2000)
    for _ in 1...1000 {
        x2 += "hi"
    }
}

Benchmark.main()
```

For more examples see Sources/BenchmarkMinimalExample and
Sources/BenchmarkSuiteExample subprojects.

## Usage

To use the library, add the following lines to your swiftpm package definition:

```
dependencies: [
    .package(url: "sso://user/shabalin/swift-benchmark",
             .branch("master"))
]
```

## Roadmap

The project is still in early stages, and only offers a basic set of utilities
for benchmarking. Feel free to file issues and feature requests to help us prioritize what features are going to be added next. 

## Contributing

Please see CONTRIBUTING.md file for details.

