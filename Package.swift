// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MegaSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MegaSwitcher", path: "Sources/MegaSwitcher")
    ]
)
