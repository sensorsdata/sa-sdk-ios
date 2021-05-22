Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "2.6.4"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.platform = :ios, "8.0"
  s.default_subspec = 'Core'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore'
  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'Common' do |c|
    core_dir = "SensorsAnalyticsSDK/Core/"
    auto_track_dir = "SensorsAnalyticsSDK/Core/AutoTrack/"
    c.source_files = core_dir + "**/*.{h,m}"
    c.public_header_files = core_dir + "SensorsAnalyticsSDK.h", core_dir + "SensorsAnalyticsSDK+Public.h", core_dir + "SAAppExtensionDataManager.h", core_dir + "SASecurityPolicy.h", core_dir + "SAConfigOptions.h", core_dir + "SAConstants.h", auto_track_dir + "SensorsAnalyticsSDK+SAAutoTrack.h" 
    c.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end
  
  s.subspec 'Core' do |c|
    c.dependency 'SensorsAnalyticsSDK/Common'
    c.dependency 'SensorsAnalyticsSDK/Gesture'
    c.dependency 'SensorsAnalyticsSDK/Visualized'
  end

  # 支持 CAID 渠道匹配
  s.subspec 'CAID' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/CAID/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/CAID/**/*.h'
  end

  # 手势采集
  s.subspec 'Gesture' do |g|
    g.dependency 'SensorsAnalyticsSDK/Common'
    g.source_files = "SensorsAnalyticsSDK/Gesture/**/*.{h,m}"
    g.private_header_files = 'SensorsAnalyticsSDK/Gesture/**/*.h'
  end

# 可视化相关功能，包含可视化全埋点和点击图
  s.subspec 'Visualized' do |f|
    f.dependency 'SensorsAnalyticsSDK/Common'
    f.source_files = "SensorsAnalyticsSDK/Visualized/**/*.{h,m}"
    f.public_header_files = 'SensorsAnalyticsSDK/Visualized/SensorsAnalyticsSDK+Visualized.h'
  end

  # 开启 GPS 定位采集
  s.subspec 'Location' do |f|
    f.frameworks = 'CoreLocation'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/Location/**/*.h'
#    f.exclude_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
  end

  # 开启设备方向采集
  s.subspec 'DeviceOrientation' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.{h,m}'
    f.private_header_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.h'
    f.frameworks = 'CoreMotion'
  end

  # 推送点击
  s.subspec 'AppPush' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/AppPush/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/AppPush/**/*.h'
  end

  # 使用 UIWebView 或者 WKWebView 进行打通
  s.subspec 'WebView' do |w|
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WebView/SensorsAnalyticsSDK+WebView.h'
  end

  # 使用 WKWebView 进行打通
  s.subspec 'WKWebView' do |w|
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WKWebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WKWebView/SensorsAnalyticsSDK+WKWebView.h'
  end

  # 允许使用私有 API，v2.0.0 已废弃，待删除
  s.subspec 'ENABLE_NO_PUBLIC_APIS' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS=1'}
  end

  # 不采集 UITabBar 点击事件 
  s.subspec 'DISABLE_AUTOTRACK_UITABBAR' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABBAR=1'}
  end

  # 采集 crash slideAdress 信息，需要打开 enableTrackAppCrash 才生效
  s.subspec 'CRASH_SLIDEADDRESS' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_CRASH_SLIDEADDRESS=1'}
  end

  # 不采集 $device_id
  s.subspec 'DISABLE_AUTOTRACK_DEVICEID' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID=1'}
  end

   # 禁用 keychain
   # 卸载重装会重新触发激活事件并且匿名 Id 可能会被重置
  s.subspec 'DISABLE_KEYCHAIN' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_KEYCHAIN=1'}
  end

  # 支持自动采集 UIViewController 子页面的 $AppViewScreen
  s.subspec 'ENABLE_CHILD_VIEWSCREEN' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN=1'}
  end

  # 禁用 UIWebView，已废弃，会在后续版本中删除
  s.subspec 'DISABLE_UIWEBVIEW' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
  end

  # 禁用私有 API，可视化全埋点模块存在私有类名字符串判断
  s.subspec 'DISABLE_PRIVATE_APIS' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS=1'}
  end 

end
