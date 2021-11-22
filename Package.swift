// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "sa-sdk-ios",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SensorsAnalyticsCore", targets: ["Core"]),
        .library(name: "SensorsAnalyticsAutoTrack", targets: ["AutoTrack"]),

    ],
    dependencies: [],
    targets: [
        .target(
            name: "Core",
            path: "SensorsAnalyticsSDK/Core/",
            resources: [.copy("SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle")],
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedLibrary("icucore"),
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
            ]
        ),
        .target(
            name: "AutoTrack",
            path: "SensorsAnalyticsSDK/AutoTrack/"
        )
    ]
)
