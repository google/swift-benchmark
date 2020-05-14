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

    public init(benchmarkName: String, suiteName: String, measurements: [Double]) {
        self.benchmarkName = benchmarkName
        self.suiteName = suiteName
        self.measurements = measurements
    }
}

extension BenchmarkResult: Encodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case iterations
        case realTime = "real_time"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(suiteName)/\(benchmarkName)", forKey: .name)
        try container.encode(measurements.count, forKey: .iterations)
        try container.encode(sum(measurements), forKey: .realTime)
    }
}
