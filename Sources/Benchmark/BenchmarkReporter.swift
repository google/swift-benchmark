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
        var nameColumn = ["name"]
        var timeColumn = ["time"]
        var stdColumn = ["std"]
        var iterationsColumn = ["iterations"]
        var widths: [Int] = []

        for result in results {
            let name: String
            if result.suiteName != "" {
                name = "\(result.suiteName): \(result.benchmarkName)"
            } else {
                name = result.benchmarkName
            }
            nameColumn.append(name)
            timeColumn.append("\(median(result.measurements)) ns")
            stdColumn.append("± \(std(result.measurements))")
            iterationsColumn.append(String(result.measurements.count))
        }

        let columns = [nameColumn, timeColumn, stdColumn, iterationsColumn]
        for column in columns {
            widths.append(column.map { $0.count }.max()!)
        }

        print("")
        for index in 0...results.count {
            for columnIndex in 0..<columns.count {
                let cell = columns[columnIndex][index]
                let padded = cell.padding(
                    toLength: widths[columnIndex], withPad: " ", startingAt: 0)
                print(padded, terminator: "  ")
            }
            print("")
            if index == 0 {
                let len = widths.reduce(0, +) + (widths.count - 1) * 2
                let line = "".padding(toLength: len, withPad: "-", startingAt: 0)
                print(line)
            }
        }
    }
}
