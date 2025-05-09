// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SensorsAnalyticsSDK",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v7)
    ],
    products: [
        // 主产品 - 核心SDK
        .library(
            name: "SensorsAnalyticsSDK",
            targets: ["SensorsAnalyticsSDKCore"]
        ),
        // 基础SDK
        .library(
            name: "SensorsAnalyticsSDKBase",
            targets: ["SensorsAnalyticsSDKBase"]
        ),
        // 位置扩展
        .library(
            name: "SensorsAnalytics_Location",
            targets: ["SensorsAnalytics_Location"]
        ),
        // 设备方向扩展
        .library(
            name: "SensorsAnalytics_DeviceOrientation",
            targets: ["SensorsAnalytics_DeviceOrientation"]
        )
    ],
    targets: [
        // 核心SDK - 二进制目标
        .binaryTarget(
            name: "SensorsAnalyticsSDKCore",
            path: "SensorsAnalyticsSDK/Source/Core/SensorsAnalyticsSDK.xcframework"
        ),
        // 基础SDK - 二进制目标
        .binaryTarget(
            name: "SensorsAnalyticsSDKBase",
            path: "SensorsAnalyticsSDK/Source/Base/SensorsAnalyticsSDK.xcframework"
        ),
        // 位置扩展 - 二进制目标
        .binaryTarget(
            name: "SensorsAnalytics_Location",
            path: "SensorsAnalytics_Location/Source/SensorsAnalytics_Location.xcframework"
        ),
        // 设备方向扩展 - 二进制目标
        .binaryTarget(
            name: "SensorsAnalytics_DeviceOrientation",
            path: "SensorsAnalytics_DeviceOrientation/Source/SensorsAnalytics_DeviceOrientation.xcframework"
        )
    ],
    swiftLanguageVersions: [.v5]
)
