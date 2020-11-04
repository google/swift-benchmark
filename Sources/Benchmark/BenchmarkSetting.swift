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

/// A marker protocol for types that are intended to be
/// be used as benchmark settings.
public protocol BenchmarkSetting {}

/// Static number of iterations to run the benchmark.
/// If this setting is missing number of iterations will
/// be computed empirically by running the benchmark.
public struct Iterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

/// Maximum number of iterations to run, while emperically
/// detecting number of iterations. 
public struct MaxIterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

/// A guaranteed number of iterations to run an discard 
/// as warmup time. 
public struct WarmupIterations: BenchmarkSetting {
    public var value: Int
    public init(_ value: Int) {
        self.value = value
    }
}

/// A regex string used to filter benchmarks that should be run.
public struct Filter: BenchmarkSetting {
    public var value: String
    public init(_ value: String) {
        self.value = value
    }
}

/// A regex string used to exclude benchmarks that should be run.
public struct FilterNot: BenchmarkSetting {
    public var value: String
    public init(_ value: String) {
        self.value = value
    }
}

/// A minimal (total) time that iterations has to run
/// to be considered significant.
public struct MinTime: BenchmarkSetting {
    public var value: Double
    public init(seconds value: Double) {
        self.value = value
    }
}

/// Time unit for reporting time results.
public struct TimeUnit: BenchmarkSetting {
    public var value: Value
    public init(_ value: Value) {
        self.value = value
    }
    public enum Value: String, ExpressibleByArgument, CustomStringConvertible {
        case ns
        case us
        case ms
        case s

        public var description: String {
            switch self {
            case .ns:
                return "ns"
            case .us:
                return "us"
            case .ms:
                return "ms"
            case .s:
                return " s"
            }
        }
    }
}

/// Time unit for reporting throughput results.
public struct InverseTimeUnit: BenchmarkSetting {
    public var value: TimeUnit.Value
    public init(_ value: TimeUnit.Value) {
        self.value = value
    }
}

/// Columns to show in the benchmark output.
public struct Columns: BenchmarkSetting {
    public var value: [String]
    public init(_ value: [String]) {
        self.value = value
    }
}

/// The output format used to show the results.
public struct Format: BenchmarkSetting {
    public var value: Value
    public init(_ value: Value) {
        self.value = value
    }
    public enum Value: String, ExpressibleByArgument {
        case console
        case csv
        case json
        case none
    }
}

/// If quiet is set to true, don't show intermediate progress updates.
public struct Quiet: BenchmarkSetting {
    public var value: Bool
    public init(_ value: Bool) {
        self.value = value
    }
}

/// An aggregate of all benchmark settings, that deduplicates
/// the settings based on their type. A setting which is defined
/// multiple times, only retains its last set value.
///
/// Settings can be indexed by their corresponding type. Helper
/// accessor methods are provided for the default set of settings.
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
        self.init(defaultSettings)
    }

    init(_ settings: [String: BenchmarkSetting]) {
        self.settings = settings
    }

    /// Access a setting of given type or return nil
    /// if it's not present.
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

    /// Convenience accessor for Iterations setting.
    public var iterations: Int? {
        return self[Iterations.self]?.value
    }

    /// Convenience accessor for MaxIterations setting.
    public var maxIterations: Int {
        if let value = self[MaxIterations.self]?.value {
            return value
        } else {
            fatalError("maxIterations must have a default.")
        }
    }

    /// Convenience accessor for WarmupIterations setting.
    public var warmupIterations: Int {
        if let value = self[WarmupIterations.self]?.value {
            return value
        } else {
            return 0
        }
    }

    /// Convenience accessor for the Filter setting.
    public var filter: String? {
        return self[Filter.self]?.value
    }

    /// Convenience accessor for the Filter setting.
    public var filterNot: String? {
        return self[FilterNot.self]?.value
    }

    /// Convenience accessor for the MinTime setting.
    public var minTime: Double {
        if let value = self[MinTime.self]?.value {
            return value
        } else {
            fatalError("minTime must have a default.")
        }
    }

    /// Convenience accessor for the TimeUnit setting. 
    public var timeUnit: TimeUnit.Value {
        if let value = self[TimeUnit.self]?.value {
            return value
        } else {
            fatalError("timeUnit must have a default.")
        }
    }

    /// Convenience accessor for the InverseTimeUnit setting. 
    public var inverseTimeUnit: TimeUnit.Value {
        if let value = self[InverseTimeUnit.self]?.value {
            return value
        } else {
            fatalError("inverseTimeUnit must have a default.")
        }
    }

    /// Convenience accessor for the Columns setting. 
    public var columns: [String]? {
        return self[Columns.self]?.value
    }

    /// Convenience accessor for the TimeUnit setting. 
    public var format: Format.Value {
        if let value = self[Format.self]?.value {
            return value
        } else {
            fatalError("format must have a default.")
        }
    }

    /// Convenience accessor for the Quiet setting. 
    public var quiet: Bool {
        if let value = self[Quiet.self]?.value {
            return value
        } else {
            fatalError("quiet must have a default.")
        }
    }
}

public let defaultSettings: [BenchmarkSetting] = [
    MaxIterations(1_000_000),
    MinTime(seconds: 1.0),
    TimeUnit(.ns),
    InverseTimeUnit(.s),
    Format(.console),
    Quiet(false),
]
