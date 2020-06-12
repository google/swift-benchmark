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

    let name: String
    let content: Content
    let alignment: Alignment

    init(name: String, content: Content, alignment: Alignment) {
        self.name = name
        self.content = content
        self.alignment = alignment
    }

    static func defaults(results: [BenchmarkResult]) -> [Column] {
        var columns = [
            // name=:.name
            Column(
                name: "name",
                content: .name,
                alignment: .left),
            // time=time.median:
            Column(
                name: "time",
                content: .value(.median(.time)),
                alignment: .right),
            // std=:time.std.divide.time.median
            Column(
                name: "std",
                content: .value(.percentage(.divide(.std(.time), .median(.time)))),
                alignment: .left),
            // iterations=iterations:
            Column(
                name: "iterations",
                content: .value(.iterations),
                alignment: .right),
        ]
        var counters: Set<String> = Set()
        var showWarmup: Bool = false
        for result in results {
            showWarmup = showWarmup || result.warmupMeasurements.count > 0
            for counter in result.counters.keys {
                counters.insert(counter)
            }
        }
        for counter in Array(counters).sorted() {
            // counter_name=counter.counter_name:
            columns.append(
                Column(
                    name: counter,
                    content: .value(.counter(counter)),
                    alignment: .right))
        }
        if showWarmup {
            // warmup=warmupTime.sum:
            columns.append(
                Column(
                    name: "warmup",
                    content: .value(.sum(.warmupTime)),
                    alignment: .right))
        }
        return columns
    }

    enum Content: Hashable {
        case name
        case value(Value)
    }

    enum Alignment: Hashable {
        case left
        case right
    }

    indirect enum Base: Hashable {
        case time
        case warmupTime
    }

    indirect enum Value: Hashable {
        case median(Base)
        case std(Base)
        case min(Base)
        case max(Base)
        case sum(Base)
        case average(Base)
        case percentile(Double, Base)
        case counter(String)
        case iterations
        case divide(Value, Value)
        case percentage(Value)
    }

    enum Unit {
        case none
        case percentage
        case time
        case inverseTime
    }

    static func evaluate(columns: [Column], results: [BenchmarkResult]) -> [Row] {
        var header: Row = [:]
        for column in columns {
            header[column] = column.name
        }

        var rows: [Row] = [header]
        for result in results {
            var row: Row = [:]
            for column in columns {
                row[column] = evaluate(content: column.content, result: result, pretty: true)
            }
            rows.append(row)
        }

        return rows
    }

    static func evaluate(content: Content, result: BenchmarkResult, pretty: Bool) -> String {
        switch content {
        case .name:
            if result.suiteName != "" {
                return "\(result.suiteName).\(result.benchmarkName)"
            } else {
                return result.benchmarkName
            }
        case .value(let value):
            let evaluated = evaluate(value: value, result: result)
            if !pretty {
                return String(evaluated)
            }
            let suffix: String = containsStd(value) ? "± " : ""
            switch unit(value) {
            case .percentage:
                return suffix + String(format: "%6.2f %%", evaluated)
            case .time:
                switch result.settings.timeUnit {
                case .ns: return suffix + "\(evaluated) ns"
                case .us: return suffix + "\(evaluated/1000.0) us"
                case .ms: return suffix + "\(evaluated/1000_000.0) ms"
                case .s: return suffix + "\(evaluated/1000_000_000.0) s"
                }
            case .inverseTime:
                switch result.settings.inverseTimeUnit {
                case .ns: return suffix + "\(evaluated) /ns"
                case .us: return suffix + "\(evaluated*1000.0) /us"
                case .ms: return suffix + "\(evaluated*1000_000.0) /ms"
                case .s: return suffix + "\(evaluated*1000_000_000.0) /s"
                }
            case .none:
                let string = String(evaluated)
                if string.hasSuffix(".0") {
                    return suffix + String(string.dropLast(2))
                } else {
                    return suffix + string
                }
            }
        }
    }

    static func containsStd(_ value: Value) -> Bool {
        switch value {
        case .std(_):
            return true
        case .median(_), .min(_), .max(_), .sum(_), .average(_), .counter(_), .iterations,
            .percentile(_, _):
            return false
        case .divide(let lhs, let rhs):
            return containsStd(lhs) || containsStd(rhs)
        case .percentage(let arg):
            return containsStd(arg)
        }
    }

    static func unit(_ value: Value) -> Unit {
        switch value {
        case .median(_), .std(_), .min(_), .max(_), .sum(_), .average(_), .percentile(_, _):
            return .time
        case .counter(_), .iterations:
            return .none
        case .divide(let lhs, let rhs):
            switch (unit(lhs), unit(rhs)) {
            case (.none, .time):
                return .inverseTime
            default:
                return .none
            }
        case .percentage(_):
            return .percentage
        }
    }

    static func evaluate(base: Base, result: BenchmarkResult) -> [Double] {
        switch base {
        case .time:
            return result.measurements
        case .warmupTime:
            return result.warmupMeasurements
        }
    }

    static func evaluate(value: Value, result: BenchmarkResult) -> Double {
        switch value {
        case .median(let arg):
            let base = evaluate(base: arg, result: result)
            return base.median
        case .std(let arg):
            let base = evaluate(base: arg, result: result)
            return base.std
        case .min(let arg):
            let base = evaluate(base: arg, result: result)
            if let value = base.min() {
                return value
            } else {
                return 0
            }
        case .max(let arg):
            let base = evaluate(base: arg, result: result)
            if let value = base.max() {
                return value
            } else {
                return 0
            }
        case .sum(let arg):
            let base = evaluate(base: arg, result: result)
            return base.sum
        case .average(let arg):
            let base = evaluate(base: arg, result: result)
            if base.count == 0 {
                return 0
            } else {
                return base.average
            }
        case .percentile(let p, let arg):
            let base = evaluate(base: arg, result: result)
            if base.count == 0 {
                return 0
            } else {
                return base.percentile(p)
            }
        case .counter(let counter):
            if let value = result.counters[counter] {
                return value
            } else {
                return 0
            }
        case .divide(let lhs, let rhs):
            return evaluate(value: lhs, result: result) / evaluate(value: rhs, result: result)
        case .percentage(let arg):
            return evaluate(value: arg, result: result) * 100.0
        case .iterations:
            return Double(result.measurements.count)
        }
    }

    static func parse(columns: String) throws -> [Column] {
        if columns.contains(",") {
            var result: [Column] = []
            for column in columns.split(separator: ",") {
                result.append(try parse(column: String(column)))
            }
            return result
        } else {
            return [try parse(column: columns)]
        }
    }

    static func parse(column: String) throws -> Column {
        var columnName = ""
        var alignment: Alignment = .left
        var rest = column

        if rest.contains("=") {
            let nameParts = rest.split(separator: "=", maxSplits: 2)
            columnName = String(nameParts[0])
            rest = String(nameParts[1])
        }
        if rest.first == ":" {
            alignment = .left
            rest = String(rest.dropFirst())
        }
        if rest.last == ":" {
            alignment = .right
            rest = String(rest.dropLast())
        }

        let content = try parse(content: rest)
        if columnName == "" {
            columnName = name(content: content)
        }

        return Column(name: columnName, content: content, alignment: alignment)
    }

    static func parse(content: String) throws -> Content {
        if content == "name" {
            return .name
        } else {
            return .value(try parse(value: content))
        }
    }

    static func parse(value: String) throws -> Value {
        try parse(value: value.split(separator: ".").map { String($0) })
    }

    static func parse(value parts: [String]) throws -> Value {
        if parts.count == 1 {
            switch parts[0] {
            case "iterations":
                return .iterations
            case let base:
                fatalError("Unrecognized base value: `\(base)`.")
            }
        } else {
            switch parts[0] {
            case "time":
                return try parse(value: .time, parts: Array(parts.dropFirst()))
            case "warmupTime":
                return try parse(value: .warmupTime, parts: Array(parts.dropFirst()))
            case "counter":
                return try parse(value: .counter(parts[1]), parts: Array(parts.dropFirst(2)))
            case "iterations":
                return try parse(value: .iterations, parts: Array(parts.dropFirst()))
            case "percentage":
                return .percentage(try parse(value: Array(parts.dropFirst())))
            case let base:
                fatalError("Unrecognized base value: `\(base)`.")
            }
        }
    }

    static func parse(value base: Base, parts: [String]) throws -> Value {
        if parts.count == 0 {
            fatalError("Need to perform operation on base value \(base).")
        }
        var result: Value
        switch parts[0] {
        case "median":
            result = .median(base)
        case "std", "standardDeviation":
            result = .std(base)
        case "min", "minimum":
            result = .min(base)
        case "max", "maximum":
            result = .max(base)
        case "sum", "total":
            result = .sum(base)
        case "avg", "average":
            result = .average(base)
        case let op:
            if op.hasPrefix("p") {
                let numstr = parts[0].dropFirst().replacingOccurrences(of: "_", with: ".")
                if let p = Double(numstr) {
                    result = .percentile(p, base)
                } else {
                    fatalError("Can't parse percentile: \(parts[1]).")
                }
            } else {
                fatalError("Can't perform `\(op)` on base value `\(base)`.")
            }
        }
        if parts.count == 1 {
            return result
        } else {
            return try parse(value: result, parts: Array(parts.dropFirst()))
        }
    }

    static func parse(value: Value, parts: [String]) throws -> Value {
        if parts.count == 0 {
            return value
        }
        switch parts[0] {
        case "div", "divide":
            return .divide(value, try parse(value: Array(parts.dropFirst())))
        case let op:
            fatalError("Can't perform `\(op)` on value `\(value)`.")
        }
    }

    static func name(content: Content) -> String {
        switch content {
        case .name:
            return "name"
        case .value(let value):
            return name(value: value)
        }
    }

    static func name(value: Value) -> String {
        switch value {
        case .median(let arg):
            return "\(name(base: arg)) (median)"
        case .std(let arg):
            return "\(name(base: arg)) (std)"
        case .min(let arg):
            return "\(name(base: arg)) (min)"
        case .max(let arg):
            return "\(name(base: arg)) (max)"
        case .sum(let arg):
            return "\(name(base: arg)) (total)"
        case .average(let arg):
            return "\(name(base: arg)) (avg)"
        case .percentile(let p, let arg):
            var string = String(p)
            if string.hasSuffix(".0") {
                string = String(string.dropLast(2))
            }
            return "\(name(base: arg)) (p\(string))"
        case .counter(let counter):
            return counter
        case .divide(let lhs, let rhs):
            return "\(name(value: lhs)) / \(name(value: rhs))"
        case .percentage(let arg):
            return "\(name(value: arg))"
        case .iterations:
            return "iterations"
        }
    }

    static func name(base: Base) -> String {
        switch base {
        case .time:
            return "time"
        case .warmupTime:
            return "warmup time"
        }
    }

    static func validate(columns: String) throws {
        let _ = try parse(columns: columns)
        return
    }
}
