// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "apptentive-ios",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "apptentive-ios",
            targets: ["apptentive-ios"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "apptentive-ios",
            path: "Apptentive",
            dependencies: []),
        .testTarget(
            name: "ApptentiveTests",
            path: "Apptentive",
            dependencies: ["apptentive-ios"]),
    ]
)
