// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArgumentParser

/// A bundle of command-line arguments, that includes
/// all of the default benchmark settings. 
public struct BenchmarkArguments: ParsableArguments {
    @Flag(help: "Overrides check to verify optimized build.")
    var allowDebugBuild: Bool = false

    @Option(help: "Run only benchmarks whose names match the regular expression.")
    var filter: String?

    @Option(help: "Exclude benchmarks whose names match the regular expression.")
    var filterNot: String?

    @Option(help: "Number of iterations to run.")
    var iterations: Int?

    @Option(help: "Number of warm-up iterations to run.")
    var warmupIterations: Int?

    @Option(help: "Minimal time to run when automatically detecting number iterations.")
    var minTime: Double?

    @Option(
        help: "Maximum number of iterations to run when automatically detecting number iterations.")
    var maxIterations: Int?

    @Option(help: "Time unit used to report the timing results.")
    var timeUnit: TimeUnit.Value?

    @Option(help: "Inverse time unit used to report throughput results.")
    var inverseTimeUnit: TimeUnit.Value?

    @Option(help: "Comma-separated list of column names to show.")
    var columns: String?

    @Option(help: "Output format (valid values are: json, csv, console, none).")
    var format: Format.Value?

    @Flag(help: "Only print final benchmark results.")
    var quiet: Bool = false

    public init() {}

    /// Conversion from command-line arguments to benchmark settings.
    public var settings: [BenchmarkSetting] {
        var result: [BenchmarkSetting] = []

        if let value = filter {
            result.append(Filter(value))
        }
        if let value = filterNot {
            result.append(FilterNot(value))
        }
        if let value = iterations {
            result.append(Iterations(value))
        }
        if let value = warmupIterations {
            result.append(WarmupIterations(value))
        }
        if let value = minTime {
            result.append(MinTime(seconds: value))
        }
        if let value = maxIterations {
            result.append(MaxIterations(value))
        }
        if let value = timeUnit {
            result.append(TimeUnit(value))
        }
        if let value = inverseTimeUnit {
            result.append(InverseTimeUnit(value))
        }
        if let value = columns {
            let names = value.split(separator: ",").map { String($0) }
            result.append(Columns(Array(names)))
        }
        if let value = format {
            result.append(Format(value))
        }
        if quiet {
            result.append(Quiet(true))
        }

        return result
    }

    /// Validate that all arguments are well-formed, or throw otherwise. 
    public mutating func validate() throws {
        var isDebug = false
        assert(
            {
                isDebug = true
                return true
            }())
        if isDebug && !allowDebugBuild {
            throw ValidationError(debugBuildErrorMessage)
        }
        if iterations != nil && iterations! < 0 {
            throw ValidationError(
                nonNegativeNumberError(flag: "--iterations", of: "integer"))
        }
        if warmupIterations != nil && warmupIterations! < 0 {
            throw ValidationError(
                nonNegativeNumberError(flag: "--warmup-iterations", of: "integer"))
        }
        if maxIterations != nil && maxIterations! <= 0 {
            throw ValidationError(positiveNumberError(flag: "--max-iterations", of: "integer"))
        }
        if minTime != nil && minTime! <= 0 {
            throw ValidationError(
                positiveNumberError(flag: "--min-time", of: "floating point number"))
        }
        if let value = columns {
            for name in value.split(separator: ",") {
                if BenchmarkColumn.registry[String(name)] == nil {
                    throw ValidationError("Unknown output column: `\(name)`.")
                }
            }
        }
    }

    var debugBuildErrorMessage: String {
        """
        Please build with optimizations enabled (`-c release` if using SwiftPM,
        `-c opt` if using bazel, or `-O` if using swiftc directly). If you would really
        like to run the benchmark without optimizations, pass the `--allow-debug-build`
        flag.
        """
    }

    func positiveNumberError(flag: String, of type: String) -> String {
        return "Value provided via \(flag) must be a positive \(type)."
    }

    func nonNegativeNumberError(flag: String, of type: String) -> String {
        return "Value provided via \(flag) must be a non-negative \(type)."
    }
}

public func parseArguments() -> [BenchmarkSetting] {
    let command = BenchmarkCommand.parseOrExit()
    return command.arguments.settings
}
