import Foundation

protocol BenchmarkReporter {
    func report(running name: String)
    func report(results: [BenchmarkResult])
}

struct PlainTextReporter: BenchmarkReporter {
    func report(running name: String) {
        print("running \(name)")
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
