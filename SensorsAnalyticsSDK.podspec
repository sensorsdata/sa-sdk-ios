Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "4.0.0"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.default_subspec = 'Core'
  s.frameworks = 'Foundation', 'SystemConfiguration'

  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'Base' do |b|
    core_dir = "SensorsAnalyticsSDK/Core/"
    b.source_files = core_dir + "**/*.{h,m}"
    b.exclude_files = core_dir + "SAAlertController.h", core_dir + "SAAlertController.m"
    b.public_header_files = core_dir + "SensorsAnalyticsSDK.h", core_dir + "SensorsAnalyticsSDK+Public.h", core_dir + "SAAppExtensionDataManager.h", core_dir + "SASecurityPolicy.h", core_dir + "SAConfigOptions.h", core_dir + "SAConstants.h"
    b.ios.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
    b.ios.frameworks = 'CoreTelephony'
  end

  s.subspec 'Extension' do |e|
    e.dependency 'SensorsAnalyticsSDK/Base'
  end

  s.subspec 'Common' do |c|
    c.dependency 'SensorsAnalyticsSDK/Extension'
    c.public_header_files = 'SensorsAnalyticsSDK/JSBridge/SensorsAnalyticsSDK+JavaScriptBridge.h'
    c.source_files = 'SensorsAnalyticsSDK/Core/SAAlertController.{h,m}', 'SensorsAnalyticsSDK/JSBridge/**/*.{h,m}'
    c.ios.source_files = 'SensorsAnalyticsSDK/RemoteConfig/**/*.{h,m}', 'SensorsAnalyticsSDK/ChannelMatch/**/*.{h,m}', 'SensorsAnalyticsSDK/Encrypt/**/*.{h,m}', 'SensorsAnalyticsSDK/Deeplink/**/*.{h,m}', 'SensorsAnalyticsSDK/DebugMode/**/*.{h,m}', 'SensorsAnalyticsSDK/Core/SAAlertController.h'
    c.ios.public_header_files = 'SensorsAnalyticsSDK/{Encrypt,RemoteConfig,ChannelMatch,Deeplink,DebugMode}/{SAConfigOptions,SensorsAnalyticsSDK}+*.h', 'SensorsAnalyticsSDK/Encrypt/SAEncryptProtocol.h', 'SensorsAnalyticsSDK/Encrypt/SASecretKey.h'
  end
  
  s.subspec 'Core' do |c|
    c.ios.dependency 'SensorsAnalyticsSDK/Visualized'
    c.osx.dependency 'SensorsAnalyticsSDK/Common'
  end

  # 支持 CAID 渠道匹配
  s.subspec 'CAID' do |f|
    f.ios.deployment_target = '8.0'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/CAID/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/CAID/**/*.h'
  end

  # 全埋点
  s.subspec 'AutoTrack' do |g|
    g.ios.deployment_target = '8.0'
    g.dependency 'SensorsAnalyticsSDK/Common'
    g.source_files = "SensorsAnalyticsSDK/AutoTrack/**/*.{h,m}"
    g.public_header_files = 'SensorsAnalyticsSDK/AutoTrack/SensorsAnalyticsSDK+SAAutoTrack.h', 'SensorsAnalyticsSDK/AutoTrack/SAConfigOptions+AutoTrack.h'
    g.frameworks = 'UIKit'
  end

# 可视化相关功能，包含可视化全埋点和点击图
  s.subspec 'Visualized' do |f|
    f.ios.deployment_target = '8.0'
    f.dependency 'SensorsAnalyticsSDK/AutoTrack'
    f.source_files = "SensorsAnalyticsSDK/Visualized/**/*.{h,m}"
    f.public_header_files = 'SensorsAnalyticsSDK/Visualized/SensorsAnalyticsSDK+Visualized.h', 'SensorsAnalyticsSDK/Visualized/SAConfigOptions+Visualized.h'
  end

  # 开启 GPS 定位采集
  s.subspec 'Location' do |f|
    f.ios.deployment_target = '8.0'
    f.frameworks = 'CoreLocation'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
    f.public_header_files = 'SensorsAnalyticsSDK/Location/SensorsAnalyticsSDK+Location.h'
  end

  # 开启设备方向采集
  s.subspec 'DeviceOrientation' do |f|
    f.ios.deployment_target = '8.0'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.{h,m}'
    f.public_header_files = 'SensorsAnalyticsSDK/DeviceOrientation/SensorsAnalyticsSDK+DeviceOrientation.h'
    f.frameworks = 'CoreMotion'
  end

  # 推送点击
  s.subspec 'AppPush' do |f|
    f.ios.deployment_target = '8.0'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/AppPush/**/*.{h,m}"
    f.public_header_files = 'SensorsAnalyticsSDK/AppPush/SAConfigOptions+AppPush.h'
  end

  # 使用崩溃事件采集
  s.subspec 'Exception' do |e|
    e.ios.deployment_target = '8.0'
    e.dependency 'SensorsAnalyticsSDK/Common'
    e.source_files  =  "SensorsAnalyticsSDK/Exception/**/*.{h,m}"
    e.public_header_files = 'SensorsAnalyticsSDK/Exception/SAConfigOptions+Exception.h'
  end

  # 基于 UA，使用 UIWebView 或者 WKWebView 进行打通
  s.subspec 'WebView' do |w|
    w.ios.deployment_target = '8.0'
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WebView/SensorsAnalyticsSDK+WebView.h'
  end

  # 基于 UA，使用 WKWebView 进行打通
  s.subspec 'WKWebView' do |w|
    w.ios.deployment_target = '8.0'
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WKWebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WKWebView/SensorsAnalyticsSDK+WKWebView.h'
  end

end
