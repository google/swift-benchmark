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

/// Functions for pretty column output formatting.
public enum BenchmarkFormatter {
    public typealias Formatter = (Double, BenchmarkSettings) -> String

    /// Show an integer number without decimals.
    public static let integer: Formatter = { (value, settings) in
        return String(format: "%.0f", value)
    }

    /// Show a real number with decimals.
    public static let real: Formatter = { (value, settings) in
        return String(format: "%.3f", value)
    }

    /// Show number with the corresponding time unit.
    public static let time: Formatter = { (value, settings) in
        let num = real(value, settings)
        return "\(num) \(settings.timeUnit)"
    }

    /// Show number with the corresponding inverse time unit.
    public static let inverseTime: Formatter = { (value, settings) in
        let num = real(value, settings)
        return "\(num) /\(settings.inverseTimeUnit)"
    }

    /// Show value as percentage.
    public static let percentage: Formatter = { (value, settings) in
        return String(format: "%6.2f %%", value)
    }

    /// Show value as plus or minus standard deviation.
    public static let std: Formatter = { (value, settings) in
        let num = real(value, settings)
        return "± \(num)"
    }

    /// Show value as plus or minus standard deviation in percentage.
    public static let stdPercentage: Formatter = { (value, settings) in
        return "± " + String(format: "%6.2f %%", value)
    }
}
