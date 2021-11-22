# swift-benchmark

A Swift library for benchmarking code snippets, similar to
[google/benchmark](https://github.com/google/benchmark).

Example:

```swift
import Benchmark

benchmark("add string reserved capacity") {
    var x: String = ""
    x.reserveCapacity(2000)
    for _ in 1...1000 {
        x += "hi"
    }
}

Benchmark.main()
```

At runtime, you can filter which benchmarks to run by using the `--filter` command line flag. For
more details on what options are available, pass either the `-h` or `--help` command line flags.

Example:

```terminal
$ swift run -c release BenchmarkMinimalExample --help
USAGE: benchmark-command [--allow-debug-build] [--filter <filter>] [--filter-not <filter-not>] [--iterations <iterations>] [--warmup-iterations <warmup-iterations>] [--min-time <min-time>] [--max-iterations <max-iterations>] [--time-unit <time-unit>] [--inverse-time-unit <inverse-time-unit>] [--columns <columns>] [--format <format>] [--quiet]

OPTIONS:
  --allow-debug-build     Overrides check to verify optimized build.
  --filter <filter>       Run only benchmarks whose names match the regular expression.
  --filter-not <filter-not>
                          Exclude benchmarks whose names match the regular expression.
  --iterations <iterations>
                          Number of iterations to run.
  --warmup-iterations <warmup-iterations>
                          Number of warm-up iterations to run.
  --min-time <min-time>   Minimal time to run when automatically detecting number iterations.
  --max-iterations <max-iterations>
                          Maximum number of iterations to run when automatically detecting number iterations.
  --time-unit <time-unit> Time unit used to report the timing results.
  --inverse-time-unit <inverse-time-unit>
                          Inverse time unit used to report throughput results.
  --columns <columns>     Comma-separated list of column names to show.
  --format <format>       Output format (valid values are: json, csv, console, none).
  --quiet                 Only print final benchmark results.
  -h, --help              Show help information.

$ swift run -c release BenchmarkMinimalExample
running add string no capacity... done! (1832.52 ms)
running add string reserved capacity... done! (1813.96 ms)

name                         time     std        iterations
-----------------------------------------------------------
add string no capacity       37435 ns ±   6.22 %      37196
add string reserved capacity 37022 ns ±   1.75 %      37749
```

For more examples, see
[Sources/BenchmarkMinimalExample](./Sources/BenchmarkMinimalExample) and
[Sources/BenchmarkSuiteExample](./Sources/BenchmarkSuiteExample).

## Usage

Add this library as a SwiftPM dependency:

```swift
let package = Package(
    name: ... ,
    products: [
        .executable(name: "Benchmarks", targets: ["Benchmarks"])
    ],
    dependencies: [
      .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Benchmarks",
            dependencies: [.product(name: "Benchmark", package: "swift-benchmark")]
        )
    ]
)
```

## Roadmap

The project is in an early stage and offers only a basic set of benchmarking
utilities. Feel free to file issues and feature requests to help us prioritize
what to do next.

## License

Please see [LICENSE](LICENSE) for details.

## Contributing

Please see [CONTRIBUTING.md] for details.

[CONTRIBUTING.md]: CONTRIBUTING.md

