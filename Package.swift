// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "sa-sdk-ios",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(name: "SensorsAnalyticsSDK", targets: ["SensorsAnalyticsSDK"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SensorsAnalyticsSDK",
            dependencies: [],
            path: "SensorsAnalyticsSDK"),
    ]
)
