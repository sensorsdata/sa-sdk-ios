Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "1.6.24"
  s.summary      = "The offical iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }

  s.source_files  = "SensorsAnalyticsSDK/SensorsAnalyticsSDK", "SensorsAnalyticsSDK/SensorsAnalyticsSDK/*.{h,m}"
  s.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK/SensorsAnalyticsSDK.h"
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore'
  s.libraries = 'icucore', 'sqlite3', 'z'
  s.platform = :ios, "7.0"

  s.subspec 'IDFA' do |f|
    f.source_files  = "SensorsAnalyticsSDK/SensorsAnalyticsSDK", "SensorsAnalyticsSDK/SensorsAnalyticsSDK/*.{h,m}"
    f.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK/SensorsAnalyticsSDK.h"
    f.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore'
    f.libraries = 'icucore', 'sqlite3', 'z'
    f.platform = :ios, "7.0"
    f.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'SENSORS_ANALYTICS_IDFA=1'}
  end

end
