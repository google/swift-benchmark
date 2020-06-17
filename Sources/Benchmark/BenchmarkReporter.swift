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

protocol BenchmarkReporter {
    mutating func report(running name: String, suite: String)
    mutating func report(finishedRunning name: String, suite: String, nanosTaken: UInt64)
    mutating func report(results: [BenchmarkResult])
}

struct PlainTextReporter<Target>: BenchmarkReporter where Target: TextOutputStream {
    enum Column: Hashable {
        case name
        case time
        case std
        case iterations
        case counter(String)
        case warmup
    }

    func title(_ column: Column) -> String {
        switch column {
        case .name: return "name"
        case .time: return "time"
        case .std: return "std"
        case .iterations: return "iterations"
        case .counter(let name): return name
        case .warmup: return "warmup"
        }
    }

    typealias Row = [Column: String]

    var output: Target

    init(to output: Target) {
        self.output = output
    }

    mutating func report(running name: String, suite: String) {
        let prefix: String
        if suite != "" {
            prefix = "\(suite): "
        } else {
            prefix = ""
        }
        print("running \(prefix)\(name)...", terminator: "", to: &output)
        if output is StdoutOutputStream {
            fflush(stdout)  // Flush stdout to actually see the message...
        }
    }

    mutating func report(finishedRunning name: String, suite: String, nanosTaken: UInt64) {
        let timeDuration = String(format: "%.2f ms", Float(nanosTaken) / 1000000.0)
        print(" done! (\(timeDuration))", to: &output)
    }

    mutating func report(results: [BenchmarkResult]) {
        var showWarmup = false
        var counters: Set<String> = Set()
        for result in results {
            showWarmup = showWarmup || result.warmupMeasurements.count > 0
            for name in result.counters.keys {
                counters.insert(name)
            }
        }

        var columns: [Column] = [.name, .time, .std, .iterations]
        if showWarmup {
            columns.append(.warmup)
        }
        for counter in counters {
            columns.append(.counter(counter))
        }
        var rows: [Row] = [Dictionary(uniqueKeysWithValues: columns.map { ($0, title($0)) })]

        for result in results {
            let name: String
            if result.suiteName != "" {
                name = "\(result.suiteName).\(result.benchmarkName)"
            } else {
                name = result.benchmarkName
            }

            let median = result.measurements.median
            let std = result.measurements.std
            let timeUnit = result.settings.timeUnit

            var row: Row = [
                .name: name,
                .time: median.formatTime(timeUnit),
                .std: "± \(String(format: "%6.2f %%", (std / median) * 100))",
                .iterations: "\(result.measurements.count)",
            ]
            if showWarmup {
                let warmup = result.warmupMeasurements
                row[.warmup] = warmup.count > 0 ? "\(warmup.sum) ns" : ""
            }
            for counter in counters {
                if let value = result.counters[counter] {
                    row[.counter(counter)] = "\(value)"
                } else {
                    row[.counter(counter)] = ""
                }
            }

            rows.append(row)
        }

        let widths: [Column: Int] = Dictionary(
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
                let string = row[column]!
                let width = widths[column]!
                switch column {
                case _ where index == 0,
                    .name, .std:
                    return string.rightPadding(toLength: width, withPad: " ")
                case .time, .iterations, .counter(_), .warmup:
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

struct StdoutOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stdout)
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

extension Double {
    fileprivate func formatTime(_ unit: TimeUnit.Value) -> String {
        switch unit {
        case .ns: return "\(self) ns"
        case .us: return "\(self/1000.0) us"
        case .ms: return "\(self/1000_000.0) ms"
        case .s: return "\(self/1000_000_000.0) s"
        }
    }
}
