Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "1.10.20"
  s.summary      = "The offical iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.platform = :ios, "7.0"
  s.default_subspec = 'core'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore', 'CoreLocation', 'CoreMotion'
  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'core' do |c|
        c.source_files = "SensorsAnalyticsSDK", "SensorsAnalyticsSDK/*.{h,m}"
        c.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK.h","SensorsAnalyticsSDK/SAAppExtensionDataManager.h"
        c.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end

  s.subspec 'LOG' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_LOG=1'}
  end

  s.subspec 'AUTOTRACT_APPVIEWSCREEN_URL' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_AUTOTRACT_APPVIEWSCREEN_URL=1'}
  end

  s.subspec 'DISABLE_CALL_STACK' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_CALL_STACK=1'}
  end

  s.subspec 'DISABLE_TRACK_GPS' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_TRACK_GPS=1'}
  end

  s.subspec 'DISABLE_TRACK_DEVICE_ORIENTATION' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION=1'}
  end

  s.subspec 'DISABLE_DEBUG_WARNING' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UICOLLECTIONVIEW' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UITABLEVIEW' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UILABEL' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UILABEL=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UIIMAGEVIEW' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGEVIEW=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_GESTURE' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_GESTURE=1'}
  end

  s.subspec 'ENABLE_REACT_NATIVE_APPCLICK' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_REACT_NATIVE=1'}
  end

  s.subspec 'ENABLE_NO_PUBLIC_APIS' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_UITABBAR' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABBAR=1'}
  end

  s.subspec 'CRASH_SLIDEADDRESS' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_CRASH_SLIDEADDRESS=1'}
  end

  s.subspec 'DISABLE_AUTOTRACK_DEVICEID' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID=1'}
  end

  s.subspec 'ENABLE_AUTOTRACK_DIDSELECTROW' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW=1'}
  end
  
  s.subspec 'DISABLE_INSTALLATION_MARK_IN_KEYCHAIN' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN=1'}
  end

  s.subspec 'ENABLE_CHILD_VIEWSCREEN' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN=1'}
  end

  s.subspec 'ENABLE_AUTOTRACK_APPSTARTPASSIVELY' do |f|
        f.dependency 'SensorsAnalyticsSDK/core'
        f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_ENABLE_AUTOTRACK_APPSTARTPASSIVELY=1'}
  end

end
