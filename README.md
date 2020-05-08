# swift-benchmark

A Swift library for benchmarking code snippets, similar to
[google/benchmark](https://github.com/google/benchmark).

Example:

```swift
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

For more examples, see Sources/BenchmarkMinimalExample and
Sources/BenchmarkSuiteExample.

## Usage

Add this library as a SwiftPM dependency:

```swift
dependencies: [
    .package(url: "https://github.com/google/swift-benchmark", .branch("master")),
]
```

## Roadmap

The project is in an early stage and offers only a basic set of benchmarking
utilities. Feel free to file issues and feature requests to help us prioritize
what to do next.

## Contributing

Please see [CONTRIBUTING.md] for details.

[CONTRIBUTING.md]: CONTRIBUTING.md
