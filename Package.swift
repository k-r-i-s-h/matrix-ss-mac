// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MatrixScreenSaver",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MatrixRainCore", targets: ["MatrixRainCore"])
    ],
    targets: [
        .target(name: "MatrixRainCore"),
        .testTarget(name: "MatrixRainCoreTests", dependencies: ["MatrixRainCore"])
    ]
)
