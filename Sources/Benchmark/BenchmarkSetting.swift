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

public protocol BenchmarkSetting {}

public struct Iterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

public struct MaxIterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

public struct WarmupIterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

public struct Filter: BenchmarkSetting {
    public var value: String
    public init(_ value: String) {
        self.value = value
    }
}

public struct MinTime: BenchmarkSetting {
    public var value: Double
    public init(seconds value: Double) {
        self.value = value
    }
}

public struct BenchmarkSettings {
    let settings: [String: Any]

    public init(_ settings: [[BenchmarkSetting]]) {
        self.init(Array(settings.joined()))
    }

    public init(_ settings: [BenchmarkSetting]) {
        var result: [String: BenchmarkSetting] = [:]

        for setting in settings {
            let key = String(describing: type(of: setting))
            result[key] = setting
        }

        self.init(result)
    }

    public init() {
        self.init([:])
    }

    init(_ settings: [String: BenchmarkSetting]) {
        self.settings = settings
    }

    public subscript<T>(type: T.Type) -> T? {
        get {
            let key = String(describing: type)
            if let value = settings[key] {
                if let valueT = value as? T {
                    return valueT
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }

    public var iterations: Int? {
        return self[Iterations.self]?.value
    }

    public var maxIterations: Int? {
        return self[MaxIterations.self]?.value
    }

    public var warmupIterations: Int? {
        return self[WarmupIterations.self]?.value
    }

    public var filter: String? {
        return self[Filter.self]?.value
    }

    public var minTime: Double? {
        return self[MinTime.self]?.value
    }
}

let defaultSettings: [BenchmarkSetting] = [
    MaxIterations(1_000_000),
    MinTime(seconds: 1.0),
]
