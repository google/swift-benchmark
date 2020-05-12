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

final class BenchmarkCommandTests: XCTestCase {
    func testAllowDebugBuild() throws {
        AssertParse(["--allow-debug-build"]) { settings in
            XCTAssert(settings.allowDebugBuild)
        }
    }

    func testDebugBuildError() {
        // Note: this can only be tested in debug builds!
        if testsAreRunningInDebugBuild {
            do {
                _ = try BenchmarkCommand.parse([])
                XCTFail("Options successfully parsed when they should not have.")
            } catch {
                let message = BenchmarkCommand.message(for: error)
                XCTAssert(message.starts(with: "Please build with optimizations enabled"), message)
            }
        }
    }

    func testParseFilter() throws {
        AssertParse(["--filter", "bar", "--allow-debug-build"]) { settings in
            XCTAssertFalse(settings.filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssert(settings.filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }

        AssertParse(["--filter", "foo/bar", "--allow-debug-build"]) { settings in
            XCTAssertFalse(settings.filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssertFalse(settings.filter.matches(suiteName: "foobar", benchmarkName: "baz"))
            XCTAssert(settings.filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }
    }

    func testParseIterations() throws {
        AssertParse(["--iterations", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.iterations, 42)
        }
    }

    func testParseZeroIterationsError() throws {
        do {
            _ = try BenchmarkCommand.parse(["--iterations", "0", "--allow-debug-build"])
            XCTFail("Options successfully parsed when they should not have.")
        } catch {
            let message = BenchmarkCommand.message(for: error)
            XCTAssert(message.starts(with: "Please make sure that number of iterations"), message)
        }
    }

    func testParseWarmupIterations() throws {
        AssertParse(["--warmup-iterations", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.warmupIterations, 42)
        }
    }

    static var allTests = [
        ("testAllowDebugBuild", testAllowDebugBuild),
        ("testDebugBuildError", testDebugBuildError),
        ("testParseFilter", testParseFilter),
        ("testParseIterations", testParseIterations),
        ("testParseZeroIterationsError", testParseZeroIterationsError),
        ("testParseWarmupIterations", testParseWarmupIterations),
    ]
}

extension BenchmarkCommandTests {
    /// Parse `arguments` and call `closure` with the resulting options.
    func AssertParse(
        _ arguments: [String],
        file: StaticString = #file,
        line: UInt = #line,
        closure: (BenchmarkSettings) -> Void
    ) {
        let parsed: BenchmarkCommand
        let settings: BenchmarkSettings
        do {
            parsed = try BenchmarkCommand.parse(arguments)
            settings = try BenchmarkSettings(parsed.settings)
        } catch {
            let message = BenchmarkCommand.message(for: error)
            XCTFail("\"\(message)\" - \(error)", file: file, line: line)
            return
        }
        closure(settings)
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
