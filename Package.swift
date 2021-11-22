// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "sa-sdk-ios",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SensorsAnalyticsCore", targets: ["SensorsAnalyticsCore"]),
        .library(name: "SensorsAnalyticsAutoTrack", targets: ["SensorsAnalyticsAutoTrack"]),

    ],
    dependencies: [],
    targets: [
        .target(
            name: "SensorsAnalyticsCore",
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
            name: "SensorsAnalyticsAutoTrack",
            path: "SensorsAnalyticsSDK/AutoTrack/"
        )
    ]
)
