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

import XCTest

@testable import Benchmark

final class BenchmarkColumnTests: XCTestCase {
    static var valueExamples: [(String, BenchmarkColumn.Value)] = [
        ("time.sum", .sum(.time)),
        ("time.median", .median(.time)),
        ("time.std", .std(.time)),
        ("time.standardDeviation", .std(.time)),
        ("time.min", .min(.time)),
        ("time.minimum", .min(.time)),
        ("time.max", .max(.time)),
        ("time.maximum", .max(.time)),
        ("time.avg", .average(.time)),
        ("time.average", .average(.time)),
        ("time.p5", .percentile(5, .time)),
        ("time.p50", .percentile(50, .time)),
        ("time.p99_9", .percentile(99.9, .time)),
        ("warmupTime.sum", .sum(.warmupTime)),
        ("warmupTime.median", .median(.warmupTime)),
        ("warmupTime.std", .std(.warmupTime)),
        ("warmupTime.standardDeviation", .std(.warmupTime)),
        ("warmupTime.min", .min(.warmupTime)),
        ("warmupTime.minimum", .min(.warmupTime)),
        ("warmupTime.max", .max(.warmupTime)),
        ("warmupTime.maximum", .max(.warmupTime)),
        ("warmupTime.avg", .average(.warmupTime)),
        ("warmupTime.average", .average(.warmupTime)),
        ("counter.foo", .counter("foo")),
        ("counter.foo.div.time.sum", .divide(.counter("foo"), .sum(.time))),
        ("counter.foo.divide.time.sum", .divide(.counter("foo"), .sum(.time))),
        ("counter.foo.divide.time.average", .divide(.counter("foo"), .average(.time))),
        ("time.std.divide.time.median", .divide(.std(.time), .median(.time))),
        (
            "percentage.time.std.divide.time.median",
            .percentage(.divide(.std(.time), .median(.time)))
        ),
    ]

    static var contentExamples: [(String, BenchmarkColumn.Content)] {
        var result: [(String, BenchmarkColumn.Content)] = [
            ("name", .name)
        ]
        for (string, value) in BenchmarkColumnTests.valueExamples {
            result.append((string, .value(value)))
        }
        return result
    }

    static var columnNames = [
        "time",
        "time (ns)",
        "time median",
        "time std",
        "time std (%)",
        "foo",
        "foo bar",
    ]

    static var alignments: [BenchmarkColumn.Alignment] = [
        .left,
        .right,
    ]

    static var columnExamples: [(String, BenchmarkColumn)] {
        var result: [(String, BenchmarkColumn)] = []
        for name in BenchmarkColumnTests.columnNames {
            for alignment in BenchmarkColumnTests.alignments {
                for (content, contentExpected) in BenchmarkColumnTests.contentExamples {
                    let rhs = alignment == .left ? ":\(content)" : "\(content):"
                    let string = "\(name)=\(rhs)"
                    let expected = BenchmarkColumn(
                        name: name, content: contentExpected, alignment: alignment)
                    result.append((string, expected))
                }
            }
        }
        return result
    }

    func testParseValue() throws {
        for (string, expected) in BenchmarkColumnTests.valueExamples {
            let parsed = try BenchmarkColumn.parse(value: string)
            XCTAssertEqual(parsed, expected, "value: \(string)")
        }
    }

    func testParseContent() throws {
        for (string, expected) in BenchmarkColumnTests.contentExamples {
            let parsed = try BenchmarkColumn.parse(content: string)
            XCTAssertEqual(parsed, expected, "content: \(string)")
        }
    }

    func testParseColumn() throws {
        for (string, expected) in BenchmarkColumnTests.columnExamples {
            let parsed = try BenchmarkColumn.parse(column: string)
            XCTAssertEqual(parsed, expected, "column: \(string)")

        }
    }

    func testParseColumns() throws {
        for (string1, expected1) in BenchmarkColumnTests.columnExamples {
            for (string2, expected2) in BenchmarkColumnTests.columnExamples {
                let string = "\(string1),\(string2)"
                let parsed = try BenchmarkColumn.parse(columns: string)
                let expected = [expected1, expected2]
                XCTAssertEqual(parsed, expected, "columns: \(string)")
            }
        }
    }

    static var allTests = [
        ("testParseValue", testParseValue),
        ("testParseContent", testParseContent),
        ("testParseColumn", testParseColumn),
        ("testParseColumns", testParseColumns),
    ]
}
