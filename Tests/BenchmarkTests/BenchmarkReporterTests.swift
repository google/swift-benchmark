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

final class BenchmarkReporterTests: XCTestCase {

    func testPaddingLeft() throws {
        let testText = "testText"
        XCTAssertEqual(testText.leftPadding(toLength: testText.count, withPad:" "), "testText")
        XCTAssertEqual(testText.leftPadding(toLength: testText.count + 3, withPad:" "), "   testText")
    }

    func testPaddingEachCell() throws {
        let dummyName = ["00", "10", "20"]
        let dummyTime = ["01", "11", "21"]
        let dummyStd = ["02", "12", "22"]
        let dummyIterations = ["03", "13", "23"]
        let columuns = [dummyName, dummyTime, dummyStd, dummyIterations]

        for index in 0..<dummyName.count {
            for columnIndex in 0..<columuns.count {
                let cell = columuns[columnIndex][index]
                let paddedCell = paddingEachCell(cell: cell,
                    index: index, columnIndex: columnIndex, length: cell.count + 1)
                if index != 0 && columnIndex == 1 {
                    XCTAssertEqual(paddedCell, " \(index)\(columnIndex)")
                } else {
                    XCTAssertEqual(paddedCell, "\(index)\(columnIndex) ")
                }
            }
        }
    }

    static var allTests = [
        ("testPaddingLeft", testPaddingLeft),
        ("testPaddingEachCell", testPaddingEachCell)
    ]
}
