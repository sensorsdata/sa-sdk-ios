Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "4.8.3"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" }
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '12.0'
  s.default_subspec = 'Core'
  s.frameworks = 'Foundation', 'SystemConfiguration'

  # 限制 CocoaPods 版本
  s.cocoapods_version = '>= 1.12.0'

  s.libraries = 'icucore', 'z'

  s.subspec '__Store' do |store|
    store.source_files = 'SensorsAnalyticsSDK/Store/*.{h,m}'
    store.public_header_files = 'SensorsAnalyticsSDK/Store/SABaseStoreManager.h', 'SensorsAnalyticsSDK/Store/SAStorePlugin.h', 'SensorsAnalyticsSDK/Store/SAAESStorePlugin.h'
  end

  s.subspec 'Base' do |base|
    core_dir = "SensorsAnalyticsSDK/Core/"
    base.source_files = core_dir + "**/*.{h,m}"
    base.exclude_files = core_dir + 'SAAlertController.{h,m}', core_dir + 'HookDelegate/**/*.{h,m}'
    base.public_header_files = core_dir + "SensorsAnalyticsSDK.h", core_dir + "SensorsAnalyticsExtension.h", core_dir + "SensorsAnalyticsSDK+Public.h", core_dir + "SASecurityPolicy.h", core_dir + "SAConfigOptions.h", core_dir + "SAConstants.h", core_dir + "PropertyPlugin/SAPropertyPlugin.h"
    base.ios.frameworks = 'CoreTelephony'
    base.dependency 'SensorsAnalyticsSDK/__Store'
    base.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/**/*'}
  end

  s.subspec 'Common' do |common|
    common.ios.deployment_target = '9.0'    
    common.osx.deployment_target = '10.13'
    common.dependency 'SensorsAnalyticsSDK/Base'
    common.frameworks = 'WebKit'
    common.public_header_files = 'SensorsAnalyticsSDK/JSBridge/SensorsAnalyticsSDK+JavaScriptBridge.h'
    common.source_files = 'SensorsAnalyticsSDK/Core/SAAlertController.{h,m}', 'SensorsAnalyticsSDK/JSBridge/**/*.{h,m}', 'SensorsAnalyticsSDK/Core/HookDelegate/**/*.{h,m}'
    common.ios.source_files = 'SensorsAnalyticsSDK/RemoteConfig/**/*.{h,m}', 'SensorsAnalyticsSDK/ChannelMatch/**/*.{h,m}', 'SensorsAnalyticsSDK/Encrypt/**/*.{h,m}', 'SensorsAnalyticsSDK/Deeplink/**/*.{h,m}', 'SensorsAnalyticsSDK/DebugMode/**/*.{h,m}', 'SensorsAnalyticsSDK/Core/SAAlertController.h', 'SensorsAnalyticsSDK/UIRelated/**/*.{h,m}'
    common.ios.public_header_files = 'SensorsAnalyticsSDK/{Encrypt,RemoteConfig,ChannelMatch,Deeplink,DebugMode}/{SAConfigOptions,SensorsAnalyticsSDK}+*.h', 'SensorsAnalyticsSDK/Encrypt/SAEncryptProtocol.h', 'SensorsAnalyticsSDK/Encrypt/SASecretKey.h', 'SensorsAnalyticsSDK/Deeplink/SASlinkCreator.h', 'SensorsAnalyticsSDK/UIRelated/UIView+SensorsAnalytics.h','SensorsAnalyticsSDK/Deeplink/SAAdvertisingConfig.h'
  end

  s.subspec 'Core' do |core|
    core.ios.dependency 'SensorsAnalyticsSDK/Visualized'
    core.osx.dependency 'SensorsAnalyticsSDK/Common'
    core.tvos.dependency 'SensorsAnalyticsSDK/Base'
  end

  # 全埋点
  s.subspec 'AutoTrack' do |auto|
    auto.platform = :ios, '9.0'
    auto.dependency 'SensorsAnalyticsSDK/Common'
    auto.source_files = "SensorsAnalyticsSDK/AutoTrack/**/*.{h,m}"
    auto.public_header_files = 'SensorsAnalyticsSDK/AutoTrack/SensorsAnalyticsSDK+SAAutoTrack.h', 'SensorsAnalyticsSDK/AutoTrack/SAConfigOptions+AutoTrack.h'
    auto.frameworks = 'UIKit'
  end

  # 可视化相关功能，包含可视化全埋点和点击分析
  s.subspec 'Visualized' do |visualized|
    visualized.platform = :ios, '9.0'
    visualized.dependency 'SensorsAnalyticsSDK/AutoTrack'
    visualized.source_files = "SensorsAnalyticsSDK/Visualized/**/*.{h,m}"
    visualized.public_header_files = 'SensorsAnalyticsSDK/Visualized/SensorsAnalyticsSDK+Visualized.h', 'SensorsAnalyticsSDK/Visualized/SAConfigOptions+Visualized.h'
  end

  # 开启 GPS 定位采集
  s.subspec 'Location' do |location|
    location.platform = :ios, '9.0'
    location.frameworks = 'CoreLocation'
    location.dependency 'SensorsAnalyticsSDK/Core'
    location.source_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
    location.public_header_files = 'SensorsAnalyticsSDK/Location/SensorsAnalyticsSDK+Location.h'
  end

  # 开启设备方向采集
  s.subspec 'DeviceOrientation' do |d|
    d.platform = :ios, '9.0'
    d.dependency 'SensorsAnalyticsSDK/Core'
    d.source_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.{h,m}'
    d.public_header_files = 'SensorsAnalyticsSDK/DeviceOrientation/SensorsAnalyticsSDK+DeviceOrientation.h'
    d.frameworks = 'CoreMotion'
  end

  # 支持推送点击
  s.subspec 'AppPush' do |push|
    push.platform = :ios, '9.0'
    push.dependency 'SensorsAnalyticsSDK/Core'
    push.source_files = "SensorsAnalyticsSDK/AppPush/**/*.{h,m}"
    push.public_header_files = 'SensorsAnalyticsSDK/AppPush/SAConfigOptions+AppPush.h'
  end

  # 支持崩溃事件采集
  s.subspec 'Exception' do |exception|
    exception.platform = :ios, '9.0'
    exception.dependency 'SensorsAnalyticsSDK/Common'
    exception.source_files  =  "SensorsAnalyticsSDK/Exception/**/*.{h,m}"
    exception.public_header_files = 'SensorsAnalyticsSDK/Exception/SAConfigOptions+Exception.h'
  end

  # 基于 UA，使用 UIWebView 或者 WKWebView 进行 App 与 H5 打通
  s.subspec 'WebView' do |web|
    web.platform = :ios, '9.0'
    web.dependency 'SensorsAnalyticsSDK/Core'
    web.source_files  =  "SensorsAnalyticsSDK/WebView/**/*.{h,m}"
    web.public_header_files = 'SensorsAnalyticsSDK/WebView/SensorsAnalyticsSDK+WebView.h'
  end

  # 基于 UA，使用 WKWebView 进行 App 与 H5 打通
  s.subspec 'WKWebView' do |web|
    web.platform = :ios, '9.0'
    web.dependency 'SensorsAnalyticsSDK/Core'
    web.source_files  =  "SensorsAnalyticsSDK/WKWebView/**/*.{h,m}"
    web.public_header_files = 'SensorsAnalyticsSDK/WKWebView/SensorsAnalyticsSDK+WKWebView.h'
  end

  s.subspec 'ApplicationExtension' do |application|
    application.platform = :ios, '9.0'
    application.dependency 'SensorsAnalyticsSDK/Base'
  	application.source_files = 'SensorsAnalyticsSDK/AppExtension/*.{h,m}'
  	application.public_header_files = 'SensorsAnalyticsSDK/AppExtension/SensorsAnalyticsSDK+SAAppExtension.h'
  end

  # 使用老版 Cell 点击全埋点采集方案，可能导致某些场景，事件漏采集。使用前建议咨询神策售后技术顾问，否则请慎重使用！
  s.subspec 'DeprecatedCellClick' do |deprecated|
    deprecated.platform = :ios, '9.0'
    deprecated.dependency 'SensorsAnalyticsSDK/Core'
    deprecated.source_files = 'CellClick_HookDelegate_Deprecated/*.{h,m}'
    deprecated.project_header_files = 'CellClick_HookDelegate_Deprecated/*.h'
  end

  # 支持曝光
  s.subspec 'Exposure' do |exposure|
    exposure.platform = :ios, '9.0'
    exposure.dependency 'SensorsAnalyticsSDK/Common'
    exposure.source_files = 'SensorsAnalyticsSDK/Exposure/**/*.{h,m}'
    exposure.public_header_files = 'SensorsAnalyticsSDK/Exposure/SAConfigOptions+Exposure.h', 'SensorsAnalyticsSDK/Exposure/SAExposureConfig.h', 'SensorsAnalyticsSDK/Exposure/SAExposureData.h', 'SensorsAnalyticsSDK/Exposure/SensorsAnalyticsSDK+Exposure.h', 'SensorsAnalyticsSDK/Exposure/UIView+ExposureIdentifier.h', 'SensorsAnalyticsSDK/Exposure/SAExposureListener.h'
  end

  # SDK 切换到英文版，运营商属性、日志和弹框提示等，都换成英文。使用前咨询神策售后技术顾问，否则请慎重使用！
  s.subspec 'EnglishResources' do |english|
    english.dependency 'SensorsAnalyticsSDK/Base'
    english.source_files = 'SpecialFileSources/SACoreResources+English.{h,m}'
    english.project_header_files = 'SpecialFileSources/SACoreResources+English.h'
  end

end
