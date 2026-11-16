// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MegaLayoutSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MegaLayoutSwitcher", path: "Sources/MegaLayoutSwitcher"),
        .testTarget(name: "MegaLayoutSwitcherTests", dependencies: ["MegaLayoutSwitcher"], path: "Tests/MegaLayoutSwitcherTests"),
    ]
)
