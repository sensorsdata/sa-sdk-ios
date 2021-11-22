// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "sa-sdk-ios",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(name: "SensorsAnalyticsAppPush", targets: ["SensorsAnalyticsAppPush"]),
        .library(name: "SensorsAnalyticsAutoTrack", targets: ["SensorsAnalyticsAutoTrack"]),
        .library(name: "SensorsAnalyticsCAID", targets: ["SensorsAnalyticsCAID"]),
        .library(name: "SensorsAnalyticsChannelMatch", targets: ["SensorsAnalyticsChannelMatch"]),
        .library(name: "SensorsAnalyticsCore", targets: ["SensorsAnalyticsCore"]),
        .library(name: "SensorsAnalyticsDebugMode", targets: ["SensorsAnalyticsDebugMode"]),
        .library(name: "SensorsAnalyticsDeeplink", targets: ["SensorsAnalyticsDeeplink"]),
        .library(name: "SensorsAnalyticsDeviceOrientation", targets: ["SensorsAnalyticsDeviceOrientation"]),
        .library(name: "SensorsAnalyticsEncrypt", targets: ["SensorsAnalyticsEncrypt"]),
        .library(name: "SensorsAnalyticsException", targets: ["SensorsAnalyticsException"]),
        .library(name: "SensorsAnalyticsJSBridge", targets: ["SensorsAnalyticsJSBridge"]),
        .library(name: "SensorsAnalyticsLocation", targets: ["SensorsAnalyticsLocation"]),
        .library(name: "SensorsAnalyticsRemoteConfig", targets: ["SensorsAnalyticsRemoteConfig"]),
        .library(name: "SensorsAnalyticsVisualized", targets: ["SensorsAnalyticsVisualized"]),
        .library(name: "SensorsAnalyticsWebView", targets: ["SensorsAnalyticsWebView"]),
        .library(name: "SensorsAnalyticsWKWebView", targets: ["SensorsAnalyticsWKWebView"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SensorsAnalyticsAppPush",
            path: "SensorsAnalyticsSDK/AppPush/"
        ),
        .target(
            name: "SensorsAnalyticsAutoTrack",
            path: "SensorsAnalyticsSDK/AutoTrack/"
        ),
        .target(
            name: "SensorsAnalyticsCAID",
            path: "SensorsAnalyticsSDK/CAID/"
        ),
        .target(
            name: "SensorsAnalyticsChannelMatch",
            path: "SensorsAnalyticsSDK/ChannelMatch/"
        ),
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
            name: "SensorsAnalyticsDebugMode",
            path: "SensorsAnalyticsSDK/DebugMode/"
        ),
        .target(
            name: "SensorsAnalyticsDeeplink",
            path: "SensorsAnalyticsSDK/Deeplink/"
        ),
        .target(
            name: "SensorsAnalyticsDeviceOrientation",
            path: "SensorsAnalyticsSDK/DeviceOrientation/"
        ),
        .target(
            name: "SensorsAnalyticsEncrypt",
            path: "SensorsAnalyticsSDK/Encrypt/"
        ),
        .target(
            name: "SensorsAnalyticsException",
            path: "SensorsAnalyticsSDK/Exception/"
        ),
        .target(
            name: "SensorsAnalyticsJSBridge",
            path: "SensorsAnalyticsSDK/JSBridge/"
        ),
        .target(
            name: "SensorsAnalyticsLocation",
            path: "SensorsAnalyticsSDK/Location/"
        ),
        .target(
            name: "SensorsAnalyticsRemoteConfig",
            path: "SensorsAnalyticsSDK/RemoteConfig/"
        ),
        .target(
            name: "SensorsAnalyticsVisualized",
            path: "SensorsAnalyticsSDK/Visualized/"
        ),
        .target(
            name: "SensorsAnalyticsWebView",
            path: "SensorsAnalyticsSDK/WebView/"
        ),
        .target(
            name: "SensorsAnalyticsWKWebView",
            path: "SensorsAnalyticsSDK/WKWebView/"
        ),
    ]
)
