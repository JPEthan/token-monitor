// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TokenMonitor",
    defaultLocalization: "zh-Hant",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TokenQuotaCore", targets: ["TokenQuotaCore"]),
        .executable(name: "TokenMonitor", targets: ["TokenMonitor"])
    ],
    targets: [
        .target(
            name: "TokenQuotaCore"
        ),
        .executableTarget(
            name: "TokenMonitor",
            dependencies: ["TokenQuotaCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Security"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "TokenQuotaCoreTests",
            dependencies: ["TokenQuotaCore"]
        )
    ]
)
