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

public protocol AnyBenchmark {
    var name: String { get }
    var settings: [BenchmarkSetting] { get }
    func setUp()
    func run(_ state: inout BenchmarkState) throws
    func tearDown()
}

extension AnyBenchmark {
    func setUp() {}
    func tearDown() {}
}

internal class ClosureBenchmark: AnyBenchmark {
    let name: String
    let settings: [BenchmarkSetting]
    let closure: () throws -> Void

    init(_ name: String, settings: [BenchmarkSetting], closure: @escaping () throws -> Void) {
        self.name = name
        self.settings = settings
        self.closure = closure
    }

    func run(_ state: inout BenchmarkState) throws {
        return try self.closure()
    }
}

internal class InoutClosureBenchmark: AnyBenchmark {
    let name: String
    let settings: [BenchmarkSetting]
    let closure: (inout BenchmarkState) throws -> Void

    init(
        _ name: String, settings: [BenchmarkSetting],
        closure: @escaping (inout BenchmarkState) throws -> Void
    ) {
        self.name = name
        self.settings = settings
        self.closure = closure
    }

    func run(_ state: inout BenchmarkState) throws {
        return try self.closure(&state)
    }
}

public func benchmark(_ name: String, function: @escaping () throws -> Void) {
    defaultBenchmarkSuite.benchmark(name, function: function)
}

public func benchmark(_ name: String, function: @escaping (inout BenchmarkState) throws -> Void) {
    defaultBenchmarkSuite.benchmark(name, function: function)
}

public func benchmark(
    _ name: String, settings: BenchmarkSetting..., function: @escaping () throws -> Void
) {
    defaultBenchmarkSuite.benchmark(name, settings: settings, function: function)
}

public func benchmark(
    _ name: String, settings: BenchmarkSetting...,
    function: @escaping (inout BenchmarkState) throws -> Void
) {
    defaultBenchmarkSuite.benchmark(name, settings: settings, function: function)
}
