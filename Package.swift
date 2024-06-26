// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SCP_APP",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.3.0"),
    ],
    targets: [
        // Main target for your application
        .target(
            name: "SCP_APP",
            dependencies: [
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
            ],
            path: "SCP_APP"
        ),
        // Test target
        .testTarget(
            name: "SCP_APPTests",
            dependencies: ["SCP_APP"],
            path: "Tests/SCP_APPTests"
        ),
    ]
)
