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

/// Run each benchmark once, to make them work as tests. 
public func runTests(suites: [BenchmarkSuite]) {
    for suite in suites {
        for benchmark in suite.benchmarks {
            benchmark.run()
        }
    }
}

/// Create a sequence of tests that can be used for XCTest.allTests.
public func makeTests<T>(_ type: T.Type, suites: [BenchmarkSuite]) -> [(String, (T) -> () -> Void)]
{
    var result: [(String, (T) -> () -> Void)] = []

    for suite in suites {
        for benchmark in suite.benchmarks {
            let name = "\(suite.name): \(benchmark.name)"
            let closure: (T) -> () -> Void = { _ in
                return {
                    benchmark.run()
                    return
                }
            }
            result.append((name, closure))
        }
    }

    return result
}
