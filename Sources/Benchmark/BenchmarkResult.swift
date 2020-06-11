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

public struct BenchmarkResult {
    public let benchmarkName: String
    public let suiteName: String
    public let measurements: [Double]
    public let counters: [String: Int]

    public init(
        benchmarkName: String, suiteName: String, measurements: [Double], counters: [String: Int]
    ) {
        self.benchmarkName = benchmarkName
        self.suiteName = suiteName
        self.measurements = measurements
        self.counters = counters
    }
}
