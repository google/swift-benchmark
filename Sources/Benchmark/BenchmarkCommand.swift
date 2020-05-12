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

    var settings: [BenchmarkSetting] {
        var result: [BenchmarkSetting] = []
        if filter != nil {
            result.append(.filter(filter!))
        }
        if iterations != nil {
            result.append(.iterations(iterations!))
        }
        if warmupIterations != nil {
            result.append(.warmupIterations(warmupIterations!))
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
            throw ValidationError(iterationsErrorMessage)
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

    var iterationsErrorMessage: String {
        "Please make sure that number of iterations is a positive integer number."
    }
}
