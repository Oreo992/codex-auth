// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexAuthStatusBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CodexAuthStatusBar", targets: ["CodexAuthStatusBar"]),
        .executable(name: "CodexAuthStatusBarSelfTest", targets: ["CodexAuthStatusBarSelfTest"])
    ],
    targets: [
        .target(
            name: "CodexAuthStatusBarCore",
            path: "Sources/CodexAuthStatusBarCore"
        ),
        .executableTarget(
            name: "CodexAuthStatusBar",
            dependencies: ["CodexAuthStatusBarCore"],
            path: "Sources/CodexAuthStatusBar"
        ),
        .executableTarget(
            name: "CodexAuthStatusBarSelfTest",
            dependencies: ["CodexAuthStatusBarCore"],
            path: "Tests"
        )
    ]
)
