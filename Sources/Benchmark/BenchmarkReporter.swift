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

import Foundation

#if canImport(OSLog)
    import OSLog
#endif

protocol ProgressReporter {
    mutating func reportWillBeginBenchmark(_ benchmark: AnyBenchmark, suite: BenchmarkSuite)
    mutating func reportFinishedBenchmark(nanosTaken: UInt64)

    mutating func reportWarmingUp()
    mutating func reportFinishedWarmup(nanosTaken: UInt64)

    mutating func reportRunning()
    mutating func reportFinishedRunning(nanosTaken: UInt64)
}

protocol BenchmarkReporter {
    mutating func report(results: [BenchmarkResult])
}

struct VerboseProgressReporter<Output: FlushableTextOutputStream>: ProgressReporter {
    var output: Output
    var currentBenchmarkQualifiedName: String
    #if canImport(OSLog)
        var currentOSLog: Any?
    #endif

    init(output: Output) {
        self.output = output
        self.currentBenchmarkQualifiedName = ""
        self.currentOSLog = nil
    }

    mutating func reportWillBeginBenchmark(_ benchmark: AnyBenchmark, suite: BenchmarkSuite) {

        let prefix: String
        if suite.name != "" {
            prefix = "\(suite.name): "
        } else {
            prefix = ""
        }
        self.currentBenchmarkQualifiedName = "\(prefix)\(benchmark.name)"
        #if canImport(OSLog)
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                currentOSLog = OSLog(
                    subsystem: currentBenchmarkQualifiedName, category: .pointsOfInterest)
            }
        #endif
    }

    mutating func reportWarmingUp() {
        print("Warming up... ", terminator: "", to: &output)
        output.flush()
        #if canImport(OSLog)
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                os_signpost(.begin, log: currentOSLog as! OSLog, name: "Warmup")
            }
        #endif
    }

    mutating func reportFinishedWarmup(nanosTaken: UInt64) {
        #if canImport(OSLog)
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                os_signpost(.end, log: currentOSLog as! OSLog, name: "Warmup")
            }
        #endif
    }

    mutating func reportRunning() {
        print("Running \(currentBenchmarkQualifiedName)... ", terminator: "", to: &output)
        output.flush()
        #if canImport(OSLog)
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                os_signpost(.begin, log: currentOSLog as! OSLog, name: "Benchmark")
            }
        #endif
    }

    mutating func reportFinishedRunning(nanosTaken: UInt64) {
        #if canImport(OSLog)
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                os_signpost(.end, log: currentOSLog as! OSLog, name: "Benchmark")
            }
        #endif
    }

    mutating func reportFinishedBenchmark(nanosTaken: UInt64) {
        let timeDuration = String(format: "%.2f ms", Float(nanosTaken) / 1000000.0)
        print("Done! (\(timeDuration))", to: &output)
        output.flush()
    }
}

struct QuietReporter: ProgressReporter, BenchmarkReporter {
    mutating func reportWillBeginBenchmark(_ benchmark: AnyBenchmark, suite: BenchmarkSuite) {}
    mutating func reportWarmingUp() {}
    mutating func reportFinishedWarmup(nanosTaken: UInt64) {}
    mutating func reportRunning() {}
    mutating func reportFinishedRunning(nanosTaken: UInt64) {}
    mutating func reportFinishedBenchmark(nanosTaken: UInt64) {}
    mutating func report(results: [BenchmarkResult]) {}
}

struct ConsoleReporter<Output: FlushableTextOutputStream>: BenchmarkReporter {
    var output: Output

    init(output: Output) {
        self.output = output
    }

    mutating func report(results: [BenchmarkResult]) {
        let (rows, columns) = BenchmarkColumn.evaluate(results: results, pretty: true)

        let widths: [BenchmarkColumn: Int] = Dictionary(
            uniqueKeysWithValues:
                columns.map { column in
                    (
                        column,
                        rows.compactMap {
                            row in row[column]?.count
                        }.max() ?? 0
                    )
                }
        )

        print("", to: &output)
        for (index, row) in rows.enumerated() {
            let components: [String] = columns.compactMap { column in
                var string: String
                if let value = row[column] {
                    string = value
                } else {
                    string = ""
                }
                let width = widths[column]!
                let alignment = index == 0 ? .left : column.alignment
                switch alignment {
                case .left:
                    return string.rightPadding(toLength: width, withPad: " ")
                case .right:
                    return string.leftPadding(toLength: width, withPad: " ")
                }
            }

            let line = components.joined(separator: " ")
            print(line, to: &output)

            if index == 0 {
                print(String(repeating: "-", count: line.count), to: &output)
            }
        }
    }
}

struct CSVReporter<Output: FlushableTextOutputStream>: BenchmarkReporter {
    var output: Output

    init(output: Output) {
        self.output = output
    }

    mutating func report(results: [BenchmarkResult]) {
        let (rows, columns) = BenchmarkColumn.evaluate(results: results, pretty: false)

        for row in rows {
            let components: [String] = columns.compactMap {
                if let value = row[$0] {
                    return value
                } else {
                    return ""
                }
            }
            let escaped = components.map { component -> String in
                if component.contains(",") || component.contains("\"") || component.contains("\n") {
                    let escaped = component.replacingOccurrences(of: "\"", with: "\"\"")
                    return "\"\(escaped)\""
                } else {
                    return component
                }
            }
            let line = escaped.joined(separator: ",")
            print(line, to: &output)
        }
    }
}

struct JSONReporter<Output: FlushableTextOutputStream>: BenchmarkReporter {
    var output: Output

    init(output: Output) {
        self.output = output
    }

    mutating func report(results: [BenchmarkResult]) {
        let (rows, columns) = BenchmarkColumn.evaluate(results: results, pretty: false)

        print("{", to: &output)
        print("  \"benchmarks\": [", to: &output)

        for (rowIndex, row) in rows.dropFirst().enumerated() {
            print("    {", to: &output)
            for (columnIndex, column) in columns.enumerated() {
                let rhs: String
                if column.name == "name" {
                    // We use json encoder here despite its poor
                    // performance to ensure that output properly
                    // escapes special characters that could be
                    // present within the benchmark name.
                    let name: String
                    if let value = row[column] {
                        name = value
                    } else {
                        name = ""
                    }
                    let data = try! JSONSerialization.data(withJSONObject: [name])
                    var encoded = String(data: data, encoding: .utf8)!
                    encoded = String(encoded.dropFirst().dropLast())
                    rhs = encoded
                } else {
                    if let value = row[column] {
                        rhs = String(value)
                    } else {
                        continue
                    }
                }
                let suffix = columnIndex != columns.count - 1 ? "," : ""
                print("      \"\(column.name)\": \(rhs)\(suffix)", to: &output)
            }
            if rowIndex != rows.count - 2 {
                print("    },", to: &output)
            } else {
                print("    }", to: &output)
            }
        }

        print("  ]", to: &output)
        print("}", to: &output)
    }
}

protocol FlushableTextOutputStream: TextOutputStream {
    mutating func flush()
}

struct StdoutOutputStream: FlushableTextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stdout)
    }

    mutating func flush() {
        fflush(stdout)
    }
}

struct StderrOutputStream: FlushableTextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }

    mutating func flush() {
        fflush(stderr)
    }
}

extension String {
    fileprivate func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        precondition(count <= newLength, "newLength must be greater than or equal to string length")
        return String(repeating: character, count: newLength - count) + self
    }

    fileprivate func rightPadding(toLength newLength: Int, withPad character: Character) -> String {
        precondition(count <= newLength, "newLength must be greater than or equal to string length")
        return self + String(repeating: character, count: newLength - count)
    }
}
