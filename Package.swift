// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARMeasureCamera",
    defaultLocalization: "en",
    platforms: [
      .macOS(.v11),
      .iOS(.v14),
      .tvOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ARMeasureCamera",
            targets: ["ARMeasureCamera"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ARMeasureCamera",
            dependencies: [],
            path: "Sources",
            resources: [.process("Resources/art.scnassets"), .copy("Resources"), .process("Resources")]
        ),
        .testTarget(
            name: "ARMeasureCameraTests",
            dependencies: ["ARMeasureCamera"]),
    ]
)
