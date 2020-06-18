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

/// Benchmark state is used to collect the 
/// benchmark measurements and view the settings it 
/// was configured with.
/// 
/// Apart from the standard benchmark loop, you can also use
/// it with customized benchmark measurement sections via either
/// `start`/`end` or `measure` functions.
public struct BenchmarkState {
    var startTime: UInt64
    var endTime: UInt64
    var measurements: [Double]

    /// A mapping from counters to their corresponding values.
    public var counters: [String: Double]

    /// Number of iterations to be run. 
    public let iterations: Int

    /// Aggregated settings for the current benchmark run. 
    public let settings: BenchmarkSettings

    @inline(__always)
    init() {
        self.init(iterations: 0, settings: BenchmarkSettings())
    }

    @inline(__always)
    init(iterations: Int, settings: BenchmarkSettings) {
        self.startTime = 0
        self.endTime = 0
        self.measurements = []
        self.measurements.reserveCapacity(iterations)
        self.counters = [:]
        self.iterations = iterations
        self.settings = settings
    }

    /// Explicitly marks the start of the measurement section.
    @inline(__always)
    public mutating func start() {
        self.endTime = 0
        self.startTime = now()
    }

    /// Explicitly marks the end of the measurement section
    /// and records the time since start of the benchmark.
    @inline(__always)
    public mutating func end() throws {
        let value = now()
        if self.endTime == 0 {
            self.endTime = value
            try record()
        }
    }

    @inline(__always)
    mutating func record() throws {
        if measurements.count < iterations {
            measurements.append(self.duration)
        } else {
            throw BenchmarkTermination()
        }
    }

    @inline(__always)
    var duration: Double {
        return Double(self.endTime - self.startTime)
    }

    @inline(__always)
    mutating func loop(_ benchmark: AnyBenchmark) throws {
        while measurements.count < iterations {
            benchmark.setUp()
            start()
            try benchmark.run(&self)
            try end()
            benchmark.tearDown()
        }
    }

    /// Run the closure within within benchmark measurement section.
    /// It may throw errors to propagate early termination to 
    /// the outer benchmark loop.
    @inline(__always)
    public mutating func measure(f: () -> Void) throws {
        start()
        f()
        try end()
    }

    /// Increment a counter by a given value (with a default of 1).
    /// If counter has never been set before, it starts with zero as the
    /// initial value.
    @inline(__always)
    public mutating func increment(counter name: String, by value: Double = 1) {
        if let oldValue = counters[name] {
            counters[name] = oldValue + value
        } else {
            counters[name] = value
        }
    }
}
