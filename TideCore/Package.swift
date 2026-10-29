// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TideCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "TideCore", targets: ["TideCore"])
    ],
    targets: [
        .target(
            name: "TideCore",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "TideCoreTests", dependencies: ["TideCore"])
    ],
    swiftLanguageModes: [.v6]
)
