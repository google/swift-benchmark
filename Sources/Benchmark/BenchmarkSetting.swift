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
    case warmupIterations(Int)
    case filter(String)
}

struct BenchmarkSettings {
    let iterations: Int
    let warmupIterations: Int
    let filter: BenchmarkFilter

    init(_ settings: [[BenchmarkSetting]]) throws {
        try self.init(Array(settings.joined()))
    }

    init(_ settings: [BenchmarkSetting]) throws {
        var iterations: Int = -1
        var warmupIterations: Int = -1
        var filter: String? = nil

        for setting in settings {
            switch setting {
            case .iterations(let value):
                iterations = value
            case .warmupIterations(let value):
                warmupIterations = value
            case .filter(let value):
                filter = value
            }
        }

        try self.init(
            iterations: iterations,
            warmupIterations: warmupIterations,
            filter: filter)
    }

    init(iterations: Int, warmupIterations: Int, filter: String?) throws {
        self.iterations = iterations
        self.warmupIterations = warmupIterations
        self.filter = try BenchmarkFilter(filter)
    }
}

let defaultSettings: [BenchmarkSetting] = [
    .iterations(100000),
    .warmupIterations(1),
]
