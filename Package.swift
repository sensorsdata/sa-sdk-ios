// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SensorsAnalyticsSDK",
    platforms: [ 
        .iOS(.v9)
    ],
    products: [
        .library(name: "SensorsAnalyticsExtension",
                 targets: [
                    "SensorsAnalyticsExtension"
                 ]),
        .library(name: "SensorsAnalyticsSDK",
                 targets: [
                    "SensorsAnalyticsSDK"
                 ]),
    ],
    targets: [
        .target(
            name: "SensorsAnalyticsExtension",
            path: ".",
            exclude: ["Example"],
            sources: ["SensorsAnalyticsSDK/Core/SAAppExtensionDataManager.m"],
            publicHeadersPath: "SensorsAnalyticsExtension/modulemap",
            cSettings: [
                .headerSearchPath("SensorsAnalyticsSDK/Core")
            ]
        ),
        .target(
            name: "SensorsAnalyticsSDK",
            dependencies: ["SensorsAnalyticsExtension"],
            path: "SensorsAnalyticsSDK",
            exclude: ["Core/SAAppExtensionDataManager.m", "CAID", "WebView"],
            resources: [.copy("SensorsAnalyticsSDK.bundle")],
            publicHeadersPath: "modulemap",
            cSettings: [
                .headerSearchPath("Core"),
                .headerSearchPath("Core/Builder"),
                .headerSearchPath("Core/Builder/EventObject"),
                .headerSearchPath("Core/EventTrackerPlugin"),
                .headerSearchPath("Core/HookDelegate"),
                .headerSearchPath("Core/Network"),
                .headerSearchPath("Core/Utils"),
                .headerSearchPath("Core/SALogger"),
                .headerSearchPath("Core/Tracker"),
                .headerSearchPath("AutoTrack"),
                .headerSearchPath("AutoTrack/AppClick"),
                .headerSearchPath("AutoTrack/AppClick/Cell"),
                .headerSearchPath("AutoTrack/AppClick/Gesture"),
                .headerSearchPath("AutoTrack/AppClick/Gesture/Target"),
                .headerSearchPath("AutoTrack/AppClick/Gesture/Processor"),
                .headerSearchPath("AutoTrack/AppEnd"),
                .headerSearchPath("AutoTrack/AppStart"),
                .headerSearchPath("AutoTrack/AppPageLeave"),
                .headerSearchPath("AutoTrack/AppViewScreen"),
                .headerSearchPath("AutoTrack/ElementInfo"),
                .headerSearchPath("AppPush"),
                .headerSearchPath("ChannelMatch"),
                .headerSearchPath("DebugMode"),
                .headerSearchPath("Deeplink"),
                .headerSearchPath("DeviceOrientation"),
                .headerSearchPath("Encrypt"),
                .headerSearchPath("Exception"),
                .headerSearchPath("Location"),
                .headerSearchPath("JSBridge"),
                .headerSearchPath("RemoteConfig"),
                .headerSearchPath("Visualized"),
                .headerSearchPath("Visualized/Config"),
                .headerSearchPath("Visualized/ElementPath"),
                .headerSearchPath("Visualized/ElementSelector"),
                .headerSearchPath("Visualized/EventCheck"),
                .headerSearchPath("Visualized/VisualProperties"),
                .headerSearchPath("Visualized/VisualProperties/ViewNode"),
                .headerSearchPath("Visualized/VisualProperties/DebugLog"),
                .headerSearchPath("Visualized/WebElementInfo"),
                .headerSearchPath("WKWebView")
            ]
        )
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .gnucxx14
)
