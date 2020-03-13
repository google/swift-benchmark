// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .testTarget(
            name: "BenchmarkTests",
            dependencies: ["Benchmark"]),
    ]
)
