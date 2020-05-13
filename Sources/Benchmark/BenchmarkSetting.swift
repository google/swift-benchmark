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

public enum BenchmarkSetting {
    case iterations(Int)
    case maxIterations(Int)
    case warmupIterations(Int)
    case filter(String)
    case minTime(seconds: Double)
}

struct BenchmarkSettings {
    let iterations: Int?
    let warmupIterations: Int?
    let maxIterations: Int
    let filter: BenchmarkFilter
    let minTime: Double

    init(_ settings: [[BenchmarkSetting]]) throws {
        try self.init(Array(settings.joined()))
    }

    init(_ settings: [BenchmarkSetting]) throws {
        var iterations: Int? = nil
        var warmupIterations: Int? = nil
        var maxIterations: Int = -1
        var filter: String? = nil
        var minTime: Double = -1

        for setting in settings {
            switch setting {
            case .iterations(let value):
                iterations = value
            case .warmupIterations(let value):
                warmupIterations = value
            case .filter(let value):
                filter = value
            case .maxIterations(let value):
                maxIterations = value
            case .minTime(let value):
                minTime = value
            }
        }

        try self.init(
            iterations: iterations,
            warmupIterations: warmupIterations,
            maxIterations: maxIterations,
            filter: filter,
            minTime: minTime)
    }

    init(
        iterations: Int?, warmupIterations: Int?, maxIterations: Int, filter: String?,
        minTime: Double
    ) throws {
        self.iterations = iterations
        self.warmupIterations = warmupIterations
        self.maxIterations = maxIterations
        self.filter = try BenchmarkFilter(filter)
        self.minTime = minTime
    }
}

let defaultSettings: [BenchmarkSetting] = [
    .maxIterations(1_000_000),
    .minTime(seconds: 1.0),
]
