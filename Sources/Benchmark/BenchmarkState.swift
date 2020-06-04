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

public struct BenchmarkState {
    var iterations: Int
    var measurements: [Double]

    @inline(__always)
    init(iterations: Int) {
        self.iterations = iterations
        self.measurements = []
    }

    @inline(__always)
    public mutating func measure(f: () -> ()) {
        var result: [Double] = []
        result.reserveCapacity(iterations)
        var clock: BenchmarkClock = BenchmarkClock()

        for _ in 1...iterations {
            clock.recordStart()
            f()
            clock.recordEnd()
            result.append(Double(clock.elapsed))
        }

        self.measurements = result
    }
}
