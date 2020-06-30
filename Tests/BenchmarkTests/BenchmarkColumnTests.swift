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
    func testKnownColumns() {
        let columns = [
            "name",
            "time",
            "std",
            "iterations",
            "warmup",
            "median",
            "min",
            "max",
            "total",
            "avg",
            "average",
            "std_abs",
            "p0",
            "p1",
            "p5",
            "p10",
            "p50",
            "p90",
            "p99",
            "p99.9",
            "p99.99",
            "p100",
        ]
        for name in columns {
            XCTAssertTrue(BenchmarkColumn.registry[name] != nil, "Column: \(name).")
        }
    }

    func testRegisterColumn() {
        BenchmarkColumn.register(
            BenchmarkColumn.registry["time"]!.renamed("foobar"))
        XCTAssertTrue(BenchmarkColumn.registry["foobar"] != nil)
    }

    func testRenamed() {
        let time = BenchmarkColumn.registry["time"]!
        XCTAssertEqual(time.name, "time")
        let mytime = time.renamed("mytime")
        XCTAssertEqual(mytime.name, "mytime")
    }

    static var allTests = [
        ("testKnownColumns", testKnownColumns),
        ("testRegisterColumn", testRegisterColumn),
        ("testRenamed", testRenamed),
    ]
}
