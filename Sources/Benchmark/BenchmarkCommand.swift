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
import Foundation

/// Allows dynamic configuration of the benchmark execution.
internal struct BenchmarkCommand: ParsableCommand {
    @Flag(help: "Overrides check to verify optimized build.")
    var allowDebugBuild: Bool

    @Option(help: "Run only benchmarks whose names match the regular expression.")
    var filter: String?

    @Option(help: "Number of iterations to run.")
    var iterations: Int?

    @Option(help: "Number of warm-up iterations to run.")
    var warmupIterations: Int?

    @Option(help: "Minimal time to run when automatically detecting number iterations.")
    var minTime: Double?

    @Option(
        help: "Maximum number of iterations to run when automatically detecting number iterations.")
    var maxIterations: Int?

    var settings: [BenchmarkSetting] {
        var result: [BenchmarkSetting] = []

        if let value = filter {
            result.append(.filter(value))
        }
        if let value = iterations {
            result.append(.iterations(value))
        }
        if let value = warmupIterations {
            result.append(.warmupIterations(value))
        }
        if let value = minTime {
            result.append(.minTime(value))
        }
        if let value = maxIterations {
            result.append(.maxIterations(value))
        }

        return result
    }

    mutating func validate() throws {
        var isDebug = false
        assert(
            {
                isDebug = true
                return true
            }())
        if isDebug && !allowDebugBuild {
            throw ValidationError(debugBuildErrorMessage)
        }
        if iterations != nil && iterations! <= 0 {
            throw ValidationError(positiveNumberError(flag: "--iterations", of: "integer"))
        }
        if warmupIterations != nil && warmupIterations! <= 0 {
            throw ValidationError(positiveNumberError(flag: "--warmup-iterations", of: "integer"))
        }
        if maxIterations != nil && maxIterations! <= 0 {
            throw ValidationError(positiveNumberError(flag: "--max-iterations", of: "integer"))
        }
        if minTime != nil && minTime! <= 0 {
            throw ValidationError(positiveNumberError(flag: "--min-time", of: "floating point number"))
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
}
