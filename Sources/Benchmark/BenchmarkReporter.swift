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

extension String {
    func leftPadding(toLength: Int, withPad: String) -> String {
        let stringLength = self.count
        if stringLength <= toLength {
            return String(repeating: withPad, count: toLength - stringLength) + self
        } else {
            #if DEBUG
            //When call fatalError(), stop all program (that include debug).
            //So return String in debug.
            return "Triggar fatalError"
            #endif
            fatalError("'toLength' must be greater than or equal to 'stringLength'.\n")
        }
    }
}

func paddingEachCell(cell: String, index: Int, columnIndex: Int, length: Int) -> String {
    var paddedCell = ""
    if index != 0 && columnIndex == 1 {
        paddedCell = cell.leftPadding(toLength: length, withPad:" ")
    } else {
        paddedCell = cell.padding(
            toLength: length, withPad: " ", startingAt: 0)
    }
    return paddedCell
}

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
            let median = result.measurements.median
            let stddev = result.measurements.std
            let stddevRatio = (stddev / median) * 100
            timeColumn.append("\(median) ns")
            stdColumn.append("± \(String(format: "%6.2f %%", stddevRatio))")
            iterationsColumn.append(String(result.measurements.count))
        }

        let columns = [nameColumn, timeColumn, stdColumn, iterationsColumn]
        for column in columns {
            widths.append(column.map { $0.count }.max()!)
        }

        print("")
        for index in 0...results.count {
            for columnIndex in 0..<columns.count {
                let paddedCell = paddingEachCell(cell: columns[columnIndex][index],
                    index: index, columnIndex: columnIndex, length: widths[columnIndex])
                print(paddedCell, terminator: "  ")
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