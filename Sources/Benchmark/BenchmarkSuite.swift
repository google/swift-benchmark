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

public class BenchmarkSuite {
    public let name: String
    public let settings: [BenchmarkSetting]
    public var benchmarks: [AnyBenchmark] = []

    public init(name: String) {
        self.name = name
        self.settings = []
    }

    public init(name: String, settings: BenchmarkSetting...) {
        self.name = name
        self.settings = settings
    }

    public init(name: String, suiteBuilder: (BenchmarkSuite) -> Void) {
        self.name = name
        self.settings = []
        suiteBuilder(self)
    }

    public init(name: String, settings: BenchmarkSetting..., suiteBuilder: (BenchmarkSuite) -> Void)
    {
        self.name = name
        self.settings = settings
        suiteBuilder(self)
    }

    public func register(benchmark: AnyBenchmark) {
        benchmarks.append(benchmark)
    }

    public func benchmark(_ name: String, function f: @escaping () throws -> Void) {
        let benchmark = ClosureBenchmark(name, settings: [], closure: f)
        register(benchmark: benchmark)
    }

    public func benchmark(
        _ name: String, function f: @escaping (inout BenchmarkState) throws -> Void
    ) {
        let benchmark = InoutClosureBenchmark(name, settings: [], closure: f)
        register(benchmark: benchmark)
    }

    public func benchmark(
        _ name: String, settings: BenchmarkSetting..., function f: @escaping () throws -> Void
    ) {
        let benchmark = ClosureBenchmark(name, settings: settings, closure: f)
        register(benchmark: benchmark)
    }

    public func benchmark(
        _ name: String, settings: BenchmarkSetting...,
        function f: @escaping (inout BenchmarkState) throws -> Void
    ) {
        let benchmark = InoutClosureBenchmark(name, settings: settings, closure: f)
        register(benchmark: benchmark)
    }

    public func benchmark(
        _ name: String, settings: [BenchmarkSetting], function f: @escaping () throws -> Void
    ) {
        let benchmark = ClosureBenchmark(name, settings: settings, closure: f)
        register(benchmark: benchmark)
    }

    public func benchmark(
        _ name: String, settings: [BenchmarkSetting],
        function f: @escaping (inout BenchmarkState) throws -> Void
    ) {
        let benchmark = InoutClosureBenchmark(name, settings: settings, closure: f)
        register(benchmark: benchmark)
    }
}

public let defaultBenchmarkSuite = BenchmarkSuite(name: "")
