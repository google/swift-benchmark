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

import Benchmark

public let addStringBenchmarks = BenchmarkSuite(name: "add string", settings: Iterations(10000)) {
    suite in
    suite.benchmark("no capacity") {
        var x1: String = ""
        for _ in 1...1000 {
            x1 += "hi"
        }
    }

    suite.benchmark("reserved capacity", settings: Iterations(10001)) {
        var x2: String = ""
        x2.reserveCapacity(2000)
        for _ in 1...1000 {
            x2 += "hi"
        }
    }
}
