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

struct PlainTextReporter: BenchmarkReporter {
    enum Column: String, CaseIterable {
        case name
        case time
        case standardDeviation = "std"
        case iterations
    }

    typealias Row = [Column: String]

    func report(running name: String, suite: String) {
        let prefix: String
        if suite != "" {
            prefix = "\(suite): "
        } else {
            prefix = ""
        }
        print("running \(prefix)\(name)...", terminator: "")
        fflush(stdout)  // Flush stdout to actually see the message...
    }

    func report(finishedRunning name: String, suite: String, nanosTaken: UInt64) {
        let timeDuration = String(format: "%.2f ms", Float(nanosTaken) / 1000000.0)
        print(" done! (\(timeDuration))")
    }

    func report(results: [BenchmarkResult]) {
        let header = Dictionary(uniqueKeysWithValues: Column.allCases.map { ($0, $0.rawValue) })

        var rows: [Row] = [header]

        for result in results {
            let name: String
            if result.suiteName != "" {
                name = "\(result.suiteName): \(result.benchmarkName)"
            } else {
                name = result.benchmarkName
            }

            let median = result.measurements.median
            let standardDeviation = result.measurements.std

            rows.append([
                .name: name,
                .time: "\(median) ns",
                .standardDeviation: "± \(String(format: "%6.2f %%", (standardDeviation / median) * 100))",
                .iterations: "\(result.measurements.count)"
            ])
        }

        let widths: [Column: Int] = Dictionary(uniqueKeysWithValues:
            Column.allCases.map { column in
                (column, rows.compactMap {
                    row in row[column]?.count }.max() ?? 0)
            }
        )

        print("")
        for (index, row) in rows.enumerated() {
            let components: [String] = Column.allCases.compactMap { column in
                let string = row[column]!
                let width = widths[column]!
                switch column {
                case .name, .standardDeviation, .iterations:
                    return string.padding(toLength: width, withPad: " ", startingAt: 0)
                case .time:
                    return string.leftPadding(toLength: width, withPad:" ")
                }
            }

            let line = components.joined(separator: " ")
            print(line)

            if index == 0 {
                print(String(repeating: "-", count: line.count))
            }
        }
    }
}

fileprivate extension String {
    func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        precondition(count <= newLength, "newLength must be greater than or equal to string length")
        return String(repeating: character, count: newLength - count) + self
    }
}
