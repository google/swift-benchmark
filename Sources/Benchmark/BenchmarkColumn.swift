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

public struct BenchmarkColumn: Hashable {
    typealias Column = BenchmarkColumn
    typealias Row = [Column: String]

    public let name: String
    public let content: (BenchmarkResult) -> Content
    public let alignment: Alignment

    public enum Content {
        case string(String)
        case time(Double)
        case inverseTime(Double)
        case percentage(Double)
        case number(Double)
    }

    public enum Alignment: Hashable {
        case left
        case right
    }

    public init(
        name: String,
        content: @escaping (BenchmarkResult) -> Content,
        alignment: Alignment
    ) {
        self.name = name
        self.content = content
        self.alignment = alignment
    }

    public static var registry: [String: BenchmarkColumn] = {
        var result: [String: BenchmarkColumn] = [:]

        // Default columns.
        result["name"] = BenchmarkColumn(
            name: "name",
            content: { result in
                if result.suiteName != "" {
                    return .string("\(result.suiteName).\(result.benchmarkName)")
                } else {
                    return .string(result.benchmarkName)
                }
            },
            alignment: .left)
        result["time"] = BenchmarkColumn(
            name: "time",
            content: { .time($0.measurements.median) },
            alignment: .right)
        result["std"] = BenchmarkColumn(
            name: "std",
            content: { .percentage($0.measurements.std / $0.measurements.median * 100) },
            alignment: .left)
        result["iterations"] = BenchmarkColumn(
            name: "iterations",
            content: { .number(Double($0.measurements.count)) },
            alignment: .right)
        result["warmup"] = BenchmarkColumn(
            name: "warmup",
            content: { .time($0.warmupMeasurements.sum) },
            alignment: .right)

        // Opt-in alternative columns.
        result["median"] = BenchmarkColumn(
            name: "median",
            content: { .time($0.measurements.median) },
            alignment: .right)
        result["min"] = BenchmarkColumn(
            name: "min",
            content: { result in
                if let value = result.measurements.min() {
                    return .time(value)
                } else {
                    return .time(0)
                }
            },
            alignment: .right)
        result["max"] = BenchmarkColumn(
            name: "max",
            content: { result in
                if let value = result.measurements.max() {
                    return .time(value)
                } else {
                    return .time(0)
                }
            },
            alignment: .right)
        result["total"] = BenchmarkColumn(
            name: "total",
            content: { .time($0.measurements.sum) },
            alignment: .right)
        result["avg"] = BenchmarkColumn(
            name: "avg",
            content: { .time($0.measurements.average) },
            alignment: .right)
        result["average"] = BenchmarkColumn(
            name: "avg",
            content: { .time($0.measurements.average) },
            alignment: .right)
        result["std_abs"] = BenchmarkColumn(
            name: "std_abs",
            content: { .number($0.measurements.std) },
            alignment: .left)
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
                content: { .time($0.measurements.percentile(v)) },
                alignment: .left)
        }

        return result
    }()

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
    }

    static func defaults(results: [BenchmarkResult]) -> [Column] {
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
                    content: { result in
                        if let value = result.counters[counter] {
                            return .number(value)
                        } else {
                            return .number(0)
                        }
                    },
                    alignment: .right))
        }

        return columns
    }

    static func evaluate(columns: [Column], results: [BenchmarkResult], pretty: Bool) -> [Row] {
        var header: Row = [:]
        for column in columns {
            header[column] = column.name
        }

        var rows: [Row] = [header]
        for result in results {
            var row: Row = [:]
            for column in columns {
                var content: String
                if !pretty {
                    switch column.content(result) {
                    case .string(let value):
                        content = value
                    case .time(let value):
                        content = String(value)
                    case .inverseTime(let value):
                        content = String(value)
                    case .percentage(let value):
                        content = String(value)
                    case .number(let value):
                        content = String(value)
                    }
                } else {
                    switch column.content(result) {
                    case .string(let value):
                        content = value
                    case .time(let value):
                        switch result.settings.timeUnit {
                        case .ns: content = "\(value) ns"
                        case .us: content = "\(value/1000.0) us"
                        case .ms: content = "\(value/1000_000.0) ms"
                        case .s: content = "\(value/1000_000_000.0) s"
                        }
                    case .inverseTime(let value):
                        switch result.settings.inverseTimeUnit {
                        case .ns: content = "\(value) /ns"
                        case .us: content = "\(value*1000.0) /us"
                        case .ms: content = "\(value*1000_000.0) /ms"
                        case .s: content = "\(value*1000_000_000.0) /s"
                        }
                    case .percentage(let value):
                        content = String(format: "%6.2f %%", value)
                    case .number(let value):
                        let string = String(value)
                        if string.hasSuffix(".0") {
                            content = String(string.dropLast(2))
                        } else {
                            content = string
                        }
                    }
                    if column.name == "std" || column.name == "std_abs" {
                        content = "± " + content
                    }
                }
                row[column] = content
            }
            rows.append(row)
        }

        return rows
    }
}
