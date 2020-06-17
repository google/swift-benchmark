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
    mutating func report(results: [BenchmarkResult], settings: BenchmarkSettings)
}

struct PlainTextReporter<Target>: BenchmarkReporter where Target: TextOutputStream {
    typealias Column = BenchmarkColumn
    typealias Row = BenchmarkColumn.Row

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

    mutating func report(results: [BenchmarkResult], settings: BenchmarkSettings) {
        var columns: [Column] = []
        if let names = settings.columns {
            for name in names {
                columns.append(BenchmarkColumn.registry[name]!)
            }
        } else {
            columns = BenchmarkColumn.defaults(results: results)
        }
        let rows = BenchmarkColumn.evaluate(columns: columns, results: results, pretty: true)

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
