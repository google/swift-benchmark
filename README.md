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

At runtime, you can filter which benchmarks to run by using the `--filter` command line flag. For
more details on what options are available, pass either the `-h` or `--help` command line flags.

Example:

```bash
$ swift run -c release BenchmarkMinimalExample -h
USAGE: benchmark-runner-options --filter <filter> [--allow-debug-build]

OPTIONS:
  --filter <filter>       Run only benchmarks whose names match the regular expression.
  --allow-debug-build     Overrides check to verify optimized build.
  -h, --help              Show help information.

$
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
