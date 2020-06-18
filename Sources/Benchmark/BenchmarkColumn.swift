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

/// A type that defines how benchmark results should be 
/// presented as an output columns.
public struct BenchmarkColumn: Hashable {
    public typealias Row = [BenchmarkColumn: String]
    public typealias Formatter = BenchmarkFormatter.Formatter

    /// Name of the column shown in the output header.
    public let name: String

    /// Function to compute a value for each cell based on results.
    public let value: (BenchmarkResult) -> Double

    /// Visual alignment to either left or right side of the column.
    public let alignment: Alignment

    /// Formatter function for pretty human-readable console output.
    public let formatter: Formatter

    public enum Alignment: Hashable {
        case left
        case right
    }

    public init(
        name: String,
        value: @escaping (BenchmarkResult) -> Double,
        alignment: Alignment,
        formatter: @escaping Formatter = BenchmarkFormatter.number
    ) {
        self.name = name
        self.value = value
        self.alignment = alignment
        self.formatter = formatter
    }

    /// Registry that represents a mapping from known column
    /// names to their corresponding column values. This
    /// registry can be modified to add custom user-defined
    /// output columns.
    public static var registry: [String: BenchmarkColumn] = {
        var result: [String: BenchmarkColumn] = [:]

        // Default columns.
        result["name"] = BenchmarkColumn(
            name: "name",
            value: { _ in return 0 },  // name is a special case
            alignment: .left)
        result["time"] = BenchmarkColumn(
            name: "time",
            value: { $0.measurements.median },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["std"] = BenchmarkColumn(
            name: "std",
            value: { $0.measurements.std / $0.measurements.median * 100 },
            alignment: .left,
            formatter: BenchmarkFormatter.stdPercentage)
        result["iterations"] = BenchmarkColumn(
            name: "iterations",
            value: { Double($0.measurements.count) },
            alignment: .right,
            formatter: BenchmarkFormatter.number)
        result["warmup"] = BenchmarkColumn(
            name: "warmup",
            value: { $0.warmupMeasurements.sum },
            alignment: .right,
            formatter: BenchmarkFormatter.time)

        // Opt-in alternative columns.
        result["median"] = BenchmarkColumn(
            name: "median",
            value: { $0.measurements.median },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["min"] = BenchmarkColumn(
            name: "min",
            value: { result in
                if let value = result.measurements.min() {
                    return (value)
                } else {
                    return (0)
                }
            },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["max"] = BenchmarkColumn(
            name: "max",
            value: { result in
                if let value = result.measurements.max() {
                    return (value)
                } else {
                    return (0)
                }
            },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["total"] = BenchmarkColumn(
            name: "total",
            value: { ($0.measurements.sum) },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["avg"] = BenchmarkColumn(
            name: "avg",
            value: { ($0.measurements.average) },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["average"] = BenchmarkColumn(
            name: "avg",
            value: { ($0.measurements.average) },
            alignment: .right,
            formatter: BenchmarkFormatter.time)
        result["std_abs"] = BenchmarkColumn(
            name: "std_abs",
            value: { ($0.measurements.std) },
            alignment: .left,
            formatter: BenchmarkFormatter.std)
        var percentiles: [Double] = []
        percentiles.append(contentsOf: (0...100).map { Double($0) })
        percentiles.append(contentsOf: [99.9, 99.99, 99.999, 99.9999])
        for v in percentiles {
            var name = "p\(v)"
            if name.hasSuffix(".0") {
                name = String(name.dropLast(2))
            }
            result[name] = BenchmarkColumn(
                name: name,
                value: { ($0.measurements.percentile(v)) },
                alignment: .left,
                formatter: BenchmarkFormatter.time)
        }

        return result
    }()

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
    }

    /// A set of columns shown by default if no user-specified
    /// --columns flag is provided.
    static func defaults(results: [BenchmarkResult]) -> [BenchmarkColumn] {
        var showWarmup: Bool = false
        var counters: Set<String> = Set()
        for result in results {
            showWarmup = showWarmup || result.warmupMeasurements.count > 0
            for counter in result.counters.keys {
                counters.insert(counter)
            }
        }

        var columns = [
            BenchmarkColumn.registry["name"]!,
            BenchmarkColumn.registry["time"]!,
            BenchmarkColumn.registry["std"]!,
            BenchmarkColumn.registry["iterations"]!,
        ]
        if showWarmup {
            columns.append(BenchmarkColumn.registry["warmup"]!)
        }
        for counter in Array(counters).sorted() {
            columns.append(
                BenchmarkColumn(
                    name: counter,
                    value: { result in
                        if let value = result.counters[counter] {
                            return value
                        } else {
                            return 0
                        }
                    },
                    alignment: .right))
        }

        return columns
    }

    /// Evaluate all cells for all columns over all results, using
    /// columns defined in settings or defaults otherwise.
    static func evaluate(results: [BenchmarkResult], settings: BenchmarkSettings, pretty: Bool) -> (
        [Row], [BenchmarkColumn]
    ) {
        var columns: [BenchmarkColumn] = []
        if let names = settings.columns {
            for name in names {
                columns.append(BenchmarkColumn.registry[name]!)
            }
        } else {
            columns = BenchmarkColumn.defaults(results: results)
        }

        let rows = BenchmarkColumn.evaluate(columns: columns, results: results, pretty: pretty)

        return (rows, columns)
    }

    /// Evaluate all cells for all columns over all results. 
    /// Pretty argument specifies if output is meant to be human-readable.
    static func evaluate(columns: [BenchmarkColumn], results: [BenchmarkResult], pretty: Bool)
        -> [Row]
    {
        var header: Row = [:]
        for column in columns {
            header[column] = column.name
        }

        var rows: [Row] = [header]
        for result in results {
            var row: Row = [:]
            for column in columns {
                var content: String
                if column.name == "name" {
                    if result.suiteName != "" {
                        content = "\(result.suiteName).\(result.benchmarkName)"
                    } else {
                        content = result.benchmarkName
                    }
                } else {
                    let value = column.value(result)
                    if pretty {
                        content = column.formatter(value, result.settings)
                    } else {
                        content = String(value)
                    }
                }
                row[column] = content
            }
            rows.append(row)
        }

        return rows
    }
}
