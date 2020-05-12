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
    case filter(String)
    case allowDebugBuild(Bool)
}

struct BenchmarkSettings {
    let iterations: Int
    let filter: BenchmarkFilter
    let allowDebugBuild: Bool

    init(_ settings: [[BenchmarkSetting]]) throws {
        try self.init(Array(settings.joined()))
    }

    init(_ settings: [BenchmarkSetting]) throws {
        var iterations: Int = -1
        var filter: String? = nil
        var allowDebugBuild: Bool = false

        for setting in settings {
            switch setting {
            case .iterations(let value):
                iterations = value
            case .filter(let value):
                filter = value
            case .allowDebugBuild(let value):
                allowDebugBuild = value
            }
        }

        try self.init(iterations: iterations, filter: filter, allowDebugBuild: allowDebugBuild)
    }

    init(iterations: Int, filter: String?, allowDebugBuild: Bool) throws {
        self.iterations = iterations
        self.filter = try BenchmarkFilter(filter)
        self.allowDebugBuild = allowDebugBuild
    }
}

let defaultSettings: [BenchmarkSetting] = [
    .iterations(100000),
    .allowDebugBuild(false),
]
