// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Benchmark",
    products: [
        .library(
            name: "Benchmark",
            targets: ["Benchmark"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Benchmark",
            dependencies: []),
        .target(
            name: "BenchmarkExample",
            dependencies: ["Benchmark"]),
        .testTarget(
            name: "BenchmarkTests",
            dependencies: ["Benchmark"]),
    ]
)
