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
        XCTAssertEqual(sum(v0), 0)
        XCTAssertEqual(sum(v1), 1)
        XCTAssertEqual(sum(v2), 10)
        XCTAssertEqual(sum(v4), 42)
        XCTAssertEqual(sum(v5), 63)
    }

    func testSumSquared() {
        let squared0: [Double] = []
        XCTAssertEqual(sumSquared(v0), sum(squared0))
        let squared1: [Double] = [0.1 * 0.1, 0.2 * 0.2, 0.3 * 0.3, 0.4 * 0.4]
        XCTAssertEqual(sumSquared(v1), sum(squared1))
        let squared2: [Double] = [1, 4, 9, 16]
        XCTAssertEqual(sumSquared(v2), sum(squared2))
        let squared3: [Double] = [1, 4, 9, 16, 25]
        XCTAssertEqual(sumSquared(v3), sum(squared3))
        let squared4: [Double] = [1764]
        XCTAssertEqual(sumSquared(v4), sum(squared4))
        let squared5: [Double] = [441, 1764]
        XCTAssertEqual(sumSquared(v5), sum(squared5))
    }

    func testMean() {
        XCTAssertEqual(mean(v0), 0)
        XCTAssertEqual(mean(v1), 0.25)
        XCTAssertEqual(mean(v2), 2.5)
        XCTAssertEqual(mean(v3), 3)
        XCTAssertEqual(mean(v4), 42)
        XCTAssertEqual(mean(v5), 31.5)
    }

    func testMedian() {
        XCTAssertEqual(median(v0), 0)
        XCTAssertEqual(median(v1), 0.25)
        XCTAssertEqual(median(v2), 2.5)
        XCTAssertEqual(median(v3), 3)
        XCTAssertEqual(median(v4), 42)
        XCTAssertEqual(median(v5), 31.5)
        XCTAssertEqual(median(v6), 42)
    }

    func testStd() {
        let std0: Double = 0.0
        XCTAssertEqual(std(v0), std0)
        let std1: Double = 0.1290994448735806
        XCTAssertEqual(std(v1), std1)
        let std2: Double = 1.2909944487358056
        XCTAssertEqual(std(v2), std2)
        let std3: Double = 1.5811388300841898
        XCTAssertEqual(std(v3), std3)
        let std4: Double = 0
        XCTAssertEqual(std(v4), std4)
        let std5: Double = 14.849242404917497
        XCTAssertEqual(std(v5), std5)
        let std6: Double = 32.07802986469088
        XCTAssertEqual(std(v6), std6)
    }

    static var allTests = [
        ("testSum", testSum),
        ("testSumSquared", testSumSquared),
        ("testMean", testMean),
        ("testMedian", testMedian),
        ("testStd", testStd),
    ]
}
