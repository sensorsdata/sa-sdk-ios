Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK-pre"
  s.version      = "1.11.11-pre"
  s.summary      = "The official iOS SDK Pre of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.platform = :ios, "7.0"
  s.default_subspec = 'core'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore', 'CoreLocation', 'CoreMotion'
  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'core' do |c|
    c.source_files  = "SensorsAnalyticsSDK/VisualizedAutoTrack/*.{h,m}", "SensorsAnalyticsSDK/*.{h,m}","SensorsAnalyticsSDK/HeatMap/*.{h,m}"
    c.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK.h","SensorsAnalyticsSDK/SAAppExtensionDataManager.h","SensorsAnalyticsSDK/SASecurityPolicy.h","SensorsAnalyticsSDK/SAConfigOptions.h","SensorsAnalyticsSDK/SAConstants.h"
    c.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end

  # 打开 log
  s.subspec 'LOG' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_LOG=1'}
  end

  # 自动采集 $referrer
  s.subspec 'AUTOTRACT_APPVIEWSCREEN_URL' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_AUTOTRACT_APPVIEWSCREEN_URL=1'}
  end

  # 禁用 GPS 定位采集，相关代码不参与编译
  s.subspec 'DISABLE_TRACK_GPS' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_TRACK_GPS=1'}
  end

  # 禁用设备方向采集
  s.subspec 'DISABLE_TRACK_DEVICE_ORIENTATION' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION=1'}
  end

  # 禁用 debugMode 下弹框提示
  s.subspec 'DISABLE_DEBUG_WARNING' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING=1'}
  end

  # 不采集 UICollectionView 点击事件
  s.subspec 'DISABLE_AUTOTRACK_UICOLLECTIONVIEW' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW=1'}
  end

  # 不采集 UITableView 点击事件
  s.subspec 'DISABLE_AUTOTRACK_UITABLEVIEW' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW=1'}
  end

  # 不采集 UIImage 的名称
  s.subspec 'DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME=1'}
  end

  # 不采集手势点击事件
  s.subspec 'DISABLE_AUTOTRACK_GESTURE' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_GESTURE=1'}
  end

  # 开启 React Native 页面控件的自动采集 $AppClick 事件
  s.subspec 'ENABLE_REACT_NATIVE_APPCLICK' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_REACT_NATIVE=1'}
  end

  # 允许使用私有 API
  s.subspec 'ENABLE_NO_PUBLIC_APIS' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS=1'}
  end

  # 不采集 UITabBar 点击事件 
  s.subspec 'DISABLE_AUTOTRACK_UITABBAR' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABBAR=1'}
  end

  # 采集 crash slideAdress 信息，需要打开 enableTrackAppCrash 才生效
  s.subspec 'CRASH_SLIDEADDRESS' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_CRASH_SLIDEADDRESS=1'}
  end

  # 不采集 $device_id
  s.subspec 'DISABLE_AUTOTRACK_DEVICEID' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID=1'}
  end

  # 支持非 UIViewController 实现 UITableView 或 UICollectionView delegate 的点击事件采集
  s.subspec 'ENABLE_AUTOTRACK_DIDSELECTROW' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW=1'}
  end

  # trackInstallation 不保存在 keychain，卸载重装会重新触发激活事件
  s.subspec 'DISABLE_INSTALLATION_MARK_IN_KEYCHAIN' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN=1'}
  end

   # 禁用 keychain
   # 卸载重装会重新触发激活事件并且匿名 Id 可能会被重置
  s.subspec 'DISABLE_KEYCHAIN' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_KEYCHAIN=1'}
  end

  # 支持自动采集 UIViewController 子页面的 $AppViewScreen
  s.subspec 'ENABLE_CHILD_VIEWSCREEN' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN=1'}
  end

  # 开启 SDK 加密
  s.subspec 'ENABLE_ENCRYPTION' do |f|
    f.dependency 'SensorsAnalyticsSDK/core'
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_ENCRYPTION=1'}
  end

end
