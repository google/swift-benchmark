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
        if testsAreRunningInDebugBuild {
            do {
                _ = try BenchmarkCommand.parse(["--allow-debug-build"])
            } catch {
                XCTFail("--alow-debug-build should not crash when running in debug build")
            }
        }
    }

    func testDebugBuildError() {
        // TODO: figure out why this is failing on Windows CI hosts only
#if !os(Windows)
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
#endif
    }

    func testParseFilter() throws {
        AssertParse(["--filter", "bar", "--allow-debug-build"]) { settings in
            let filter = try! BenchmarkFilter(settings.filter, negate: false)
            XCTAssertFalse(filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssert(filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }

        AssertParse(["--filter", "foo.bar", "--allow-debug-build"]) { settings in
            let filter = try! BenchmarkFilter(settings.filter, negate: false)
            XCTAssertFalse(filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssertFalse(filter.matches(suiteName: "foobar", benchmarkName: "baz"))
            XCTAssert(filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }
    }

    func testParseFilterNot() throws {
        AssertParse(["--filter-not", "bar", "--allow-debug-build"]) { settings in
            let filter = try! BenchmarkFilter(settings.filterNot, negate: true)
            XCTAssert(filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssertFalse(filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }

        AssertParse(["--filter-not", "foo.bar", "--allow-debug-build"]) { settings in
            let filter = try! BenchmarkFilter(settings.filterNot, negate: true)
            XCTAssert(filter.matches(suiteName: "foo", benchmarkName: "baz"))
            XCTAssert(filter.matches(suiteName: "foobar", benchmarkName: "baz"))
            XCTAssertFalse(filter.matches(suiteName: "foo", benchmarkName: "bar"))
        }
    }

    func testParseIterations() throws {
        AssertParse(["--iterations", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.iterations, 42)
        }
    }

    func testParseZeroIterations() throws {
        AssertParse(["--iterations", "0", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.iterations, 0)
        }
    }

    func testParseWarmupIterations() throws {
        AssertParse(["--warmup-iterations", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.warmupIterations, 42)
        }
    }

    func testParseZeroWarmupIterations() throws {
        AssertParse(["--warmup-iterations", "0", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.warmupIterations, 0)
        }
    }

    func testParseNoWarmupIterations() throws {
        AssertParse(["--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.warmupIterations, 0)
        }
    }

    func testParseMaxIterations() throws {
        AssertParse(["--max-iterations", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.maxIterations, 42)
        }
    }

    func testParseZeroMaxIterationsError() throws {
        AssertFailsToParse(
            ["--max-iterations", "0", "--allow-debug-build"],
            with: "Value provided via --max-iterations must be a positive integer.")
    }

    func testParseMinTime() throws {
        AssertParse(["--min-time", "42", "--allow-debug-build"]) { settings in
            XCTAssertEqual(settings.minTime, 42)
        }
    }

    func testParseZeroMinTimeError() throws {
        AssertFailsToParse(
            ["--min-time", "0", "--allow-debug-build"],
            with: "Value provided via --min-time must be a positive floating point number.")
    }

    static var allTests = [
        ("testAllowDebugBuild", testAllowDebugBuild),
        ("testDebugBuildError", testDebugBuildError),
        ("testParseFilter", testParseFilter),
        ("testParseFilterNot", testParseFilterNot),
        ("testParseIterations", testParseIterations),
        ("testParseZeroIterations", testParseZeroIterations),
        ("testParseWarmupIterations", testParseWarmupIterations),
        ("testParseZeroWarmupIterations", testParseZeroWarmupIterations),
        ("testParseNoWarmupIterations", testParseNoWarmupIterations),
        ("testParseMaxIterations", testParseWarmupIterations),
        ("testParseZeroMaxIterationsError", testParseZeroMaxIterationsError),
        ("testParseMinTime", testParseMinTime),
        ("testParseZeroMinTimeError", testParseZeroMinTimeError),
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
            settings = BenchmarkSettings(parsed.arguments.settings)
        } catch {
            let message = BenchmarkCommand.message(for: error)
            XCTFail("\"\(message)\" - \(error)", file: file, line: line)
            return
        }
        closure(settings)
    }

    func AssertFailsToParse(_ arguments: [String], with message: String) {
        do {
            _ = try BenchmarkCommand.parse(arguments)
            XCTFail("Options successfully parsed when they should not have.")
        } catch {
            let message = BenchmarkCommand.message(for: error)
            XCTAssert(message.starts(with: message))
        }
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
