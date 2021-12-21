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
            path: "SensorsAnalyticsSDK/AppPush/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsAutoTrack",
            path: "SensorsAnalyticsSDK/AutoTrack/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsCAID",
            path: "SensorsAnalyticsSDK/CAID/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsChannelMatch",
            path: "SensorsAnalyticsSDK/ChannelMatch/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsCore",
            path: "SensorsAnalyticsSDK/Core/",
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedLibrary("icucore"),
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
            ]
        ),
        .target(
            name: "SensorsAnalyticsDebugMode",
            path: "SensorsAnalyticsSDK/DebugMode/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsDeeplink",
            path: "SensorsAnalyticsSDK/Deeplink/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsDeviceOrientation",
            path: "SensorsAnalyticsSDK/DeviceOrientation/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsEncrypt",
            path: "SensorsAnalyticsSDK/Encrypt/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsException",
            path: "SensorsAnalyticsSDK/Exception/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsJSBridge",
            path: "SensorsAnalyticsSDK/JSBridge/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsLocation",
            path: "SensorsAnalyticsSDK/Location/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsRemoteConfig",
            path: "SensorsAnalyticsSDK/RemoteConfig/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsVisualized",
            path: "SensorsAnalyticsSDK/Visualized/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsWebView",
            path: "SensorsAnalyticsSDK/WebView/",
            publicHeadersPath: "."
        ),
        .target(
            name: "SensorsAnalyticsWKWebView",
            path: "SensorsAnalyticsSDK/WKWebView/",
            publicHeadersPath: "."
        ),
    ]
)
