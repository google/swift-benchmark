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

final class BenchmarkRunnerOptionsTests: XCTestCase {
    func testAllowDebugBuild() throws {
        AssertParse(["--allow-debug-build"]) { options in
            XCTAssert(options.allowDebugBuild)
        }
    }

    func testDebugBuildError() {
        // Note: this can only be tested in debug builds!
        if testsAreRunningInDebugBuild {
            do {
                _ = try BenchmarkRunnerOptions.parse([])
                XCTFail("Options successfully parsed when they should not have.")
            } catch {
                let message = BenchmarkRunnerOptions.message(for: error)
                XCTAssert(message.starts(with: "Please build with optimizations enabled"), message)
            }
        }
    }

    func testParseFilter() throws {
        AssertParse(["--filter", "bar", "--allow-debug-build"]) { options in
            XCTAssertFalse(options.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssert(options.matches(suiteName: "foo", benchmarkName: "bar"))
        }

        AssertParse(["--filter", "foo/bar", "--allow-debug-build"]) { options in
            XCTAssertFalse(options.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssertFalse(options.matches(suiteName: "foobar", benchmarkName: "baz"))
            XCTAssert(options.matches(suiteName: "foo", benchmarkName: "bar"))
        }
    }

    static var allTests = [
        ("testAllowDebugBuild", testAllowDebugBuild),
        ("testDebugBuildError", testDebugBuildError),
        ("testParseFilter", testParseFilter),
    ]
}

extension BenchmarkRunnerOptionsTests {
    /// Parse `arguments` and call `closure` with the resulting options.
    func AssertParse(
        _ arguments: [String],
        file: StaticString = #file,
        line: UInt = #line,
        closure: (BenchmarkRunnerOptions) -> Void
    ) {
        let parsed: BenchmarkRunnerOptions
        do {
            parsed = try BenchmarkRunnerOptions.parse(arguments)
        } catch {
            let message = BenchmarkRunnerOptions.message(for: error)
            XCTFail("\"\(message)\" - \(error)", file: file, line: line)
            return
        }
        closure(parsed)
    }

    var testsAreRunningInDebugBuild: Bool {
        var isDebug = false
        assert(
            {
                isDebug = true
                return true
            }())  // assert takes an autoclosure!
        return isDebug
    }
}
