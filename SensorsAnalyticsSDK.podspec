Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "5.0.1"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" }
  s.license = {
    :type => 'Commercial',
    :file => 'LICENSE'
  }
  s.author = { "caojiang" => "caojiang@sensorsdata.cn" }
  s.default_subspec = 'Core'
  s.frameworks = 'Foundation'
  s.libraries = "icucore", "z"

  # 限制 CocoaPods 版本
  s.cocoapods_version = '>= 1.12.0'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = "7.0"

  base_dir = 'SensorsAnalyticsSDK/'

  s.subspec 'Core' do |core|
    core.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    core.watchos.frameworks = 'WatchKit'
    core.osx.frameworks = 'SystemConfiguration', 'WebKit'
    core.tvos.frameworks = 'SystemConfiguration'

    core.ios.vendored_frameworks = base_dir + 'Source/Core/SensorsAnalyticsSDK.xcframework'
    core.tvos.vendored_frameworks = base_dir + 'Source/Base/SensorsAnalyticsSDK.xcframework'
    core.osx.vendored_frameworks = base_dir + 'Source/Base/SensorsAnalyticsSDK.xcframework'
    core.watchos.vendored_frameworks = base_dir + 'Source/Base/SensorsAnalyticsSDK.xcframework'
    
    core.ios.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Core/**/*'}
    core.watchos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    core.tvos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    core.osx.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Base' do |base|
    base.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    base.watchos.frameworks = 'WatchKit'
    base.osx.frameworks = 'SystemConfiguration', 'WebKit'
    base.tvos.frameworks = 'SystemConfiguration', 'UIKit'

    base.vendored_frameworks = base_dir + 'Source/Base/SensorsAnalyticsSDK.xcframework'
    base.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Exposure' do |exposure|
    exposure.dependency 'SensorsAnalyticsSDK/Core'
    exposure.resource_bundle = { 'SAExposureResources' => 'SensorsAnalyticsSDK/Resources/Exposure/*'}
  end

  s.subspec 'EnglishResources' do |english|
    english.dependency 'SensorsAnalyticsSDK/Core'
    english.resource_bundle = { 'SAEnglishResources' => 'SensorsAnalyticsSDK/Resources/EnglishResources/*'}
  end

end
