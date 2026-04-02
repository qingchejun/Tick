// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tick",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Tick",
            path: "Sources/Tick",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
