// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "HikApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "HikApp", targets: ["HikApp"])
    ],
    targets: [
        .executableTarget(
            name: "HikApp",
            path: "Sources",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)