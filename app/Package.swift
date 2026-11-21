// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Wailo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Wailo", targets: ["Wailo"])
    ],
    targets: [
        .executableTarget(
            name: "Wailo",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "WailoTests",
            dependencies: ["Wailo"]
        )
    ]
)
