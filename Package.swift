// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoodV6",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MoodV6",
            targets: ["MoodV6"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0")
    ],
    targets: [
        .target(
            name: "MoodV6",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift")
            ]),
        .testTarget(
            name: "MoodV6Tests",
            dependencies: ["MoodV6"]),
    ]
) 