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
        .library(
            name: "ARMeasureCamera",
            targets: ["ARMeasureCamera"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ARMeasureCamera",
            dependencies: [],
            resources: [
                .process("Media.xcassets"),
                .copy("Resources/Focus_1.scn"),
                .copy("Resources/target.png")
            ]
        ),
        .testTarget(
            name: "ARMeasureCameraTests",
            dependencies: ["ARMeasureCamera"]),
    ]
)
