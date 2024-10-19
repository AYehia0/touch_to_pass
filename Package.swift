// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "touch_to_pass",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "touch_to_pass", targets: ["touch_to_pass"]),
    ],
    dependencies: [
        // Including SwiftOTP as a dependency for the package
        .package(url: "https://github.com/lachlanbell/SwiftOTP.git", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "touch_to_pass",
            dependencies: [
                "SwiftOTP",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/touch_to_pass"
        ),
    ]
)
