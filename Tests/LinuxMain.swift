import XCTest

import BenchmarkTests

var tests = [XCTestCaseEntry]()
tests += BenchmarkTests.allTests()
XCTMain(tests)
