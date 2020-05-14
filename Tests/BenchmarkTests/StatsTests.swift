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

final class StatsTests: XCTestCase {
    let v0: [Double] = []
    let v1: [Double] = [0.1, 0.2, 0.3, 0.4]
    let v2: [Double] = [1, 2, 3, 4]
    let v3: [Double] = [1, 2, 3, 4, 5]
    let v4: [Double] = [42]
    let v5: [Double] = [21, 42]
    let v6: [Double] = [21, 42, 84]

    func testSum() {
        XCTAssertEqual(v0.sum, 0)
        XCTAssertEqual(v1.sum, 1)
        XCTAssertEqual(v2.sum, 10)
        XCTAssertEqual(v4.sum, 42)
        XCTAssertEqual(v5.sum, 63)
    }

    func testSumSquared() {
        let squared0: [Double] = []
        XCTAssertEqual(v0.sumSquared, squared0.sum)
        let squared1: [Double] = [0.1 * 0.1, 0.2 * 0.2, 0.3 * 0.3, 0.4 * 0.4]
        XCTAssertEqual(v1.sumSquared, squared1.sum)
        let squared2: [Double] = [1, 4, 9, 16]
        XCTAssertEqual(v2.sumSquared, squared2.sum)
        let squared3: [Double] = [1, 4, 9, 16, 25]
        XCTAssertEqual(v3.sumSquared, squared3.sum)
        let squared4: [Double] = [1764]
        XCTAssertEqual(v4.sumSquared, squared4.sum)
        let squared5: [Double] = [441, 1764]
        XCTAssertEqual(v5.sumSquared, squared5.sum)
    }

    func testMean() {
        XCTAssertEqual(v0.mean, 0)
        XCTAssertEqual(v1.mean, 0.25)
        XCTAssertEqual(v2.mean, 2.5)
        XCTAssertEqual(v3.mean, 3)
        XCTAssertEqual(v4.mean, 42)
        XCTAssertEqual(v5.mean, 31.5)
    }

    func testMedian() {
        XCTAssertEqual(v0.median, 0)
        XCTAssertEqual(v1.median, 0.25)
        XCTAssertEqual(v2.median, 2.5)
        XCTAssertEqual(v3.median, 3)
        XCTAssertEqual(v4.median, 42)
        XCTAssertEqual(v5.median, 31.5)
        XCTAssertEqual(v6.median, 42)
    }

    func testStd() {
        let std0: Double = 0.0
        XCTAssertEqual(v0.std, std0)
        let std1: Double = 0.1290994448735806
        XCTAssertEqual(v1.std, std1)
        let std2: Double = 1.2909944487358056
        XCTAssertEqual(v2.std, std2)
        let std3: Double = 1.5811388300841898
        XCTAssertEqual(v3.std, std3)
        let std4: Double = 0
        XCTAssertEqual(v4.std, std4)
        let std5: Double = 14.849242404917497
        XCTAssertEqual(v5.std, std5)
        let std6: Double = 32.07802986469088
        XCTAssertEqual(v6.std, std6)
    }

    static var allTests = [
        ("testSum", testSum),
        ("testSumSquared", testSumSquared),
        ("testMean", testMean),
        ("testMedian", testMedian),
        ("testStd", testStd),
    ]
}
