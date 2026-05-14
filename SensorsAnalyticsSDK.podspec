Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "5.0.10"
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
  dynamic_IDFA_dir = 'IDFA_Dynamic/'
  att_IDFA_dir = 'IDFA_ATT/'
  no_IDFA_dir = 'NO_IDFA/'

  s.subspec 'Core' do |core|
    core.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    core.watchos.frameworks = 'WatchKit'
    core.osx.frameworks = 'SystemConfiguration', 'WebKit'
    core.tvos.frameworks = 'SystemConfiguration', 'UIKit'

    core.ios.vendored_frameworks = base_dir + 'Source/Core/' + dynamic_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    core.tvos.vendored_frameworks = base_dir + 'Source/Base/' + dynamic_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    core.osx.vendored_frameworks = base_dir + 'Source/Base/' + dynamic_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    core.watchos.vendored_frameworks = base_dir + 'Source/Base/' + dynamic_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    
    core.ios.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Core/**/*'}
    core.watchos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    core.tvos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    core.osx.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Core_ATT' do |coreATT|
    coreATT.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit', 'AdSupport'
    coreATT.ios.weak_framework = 'AppTrackingTransparency'
    coreATT.watchos.frameworks = 'WatchKit'
    coreATT.osx.frameworks = 'SystemConfiguration', 'WebKit'
    coreATT.tvos.frameworks = 'SystemConfiguration', 'UIKit'
    coreATT.tvos.weak_framework = 'AppTrackingTransparency'

    coreATT.ios.vendored_frameworks = base_dir + 'Source/Core/' + att_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreATT.tvos.vendored_frameworks = base_dir + 'Source/Base/' + att_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreATT.osx.vendored_frameworks = base_dir + 'Source/Base/' + att_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreATT.watchos.vendored_frameworks = base_dir + 'Source/Base/' + att_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    
    coreATT.ios.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Core/**/*'}
    coreATT.watchos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    coreATT.tvos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    coreATT.osx.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Core_NO_IDFA' do |coreNo|
    coreNo.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    coreNo.watchos.frameworks = 'WatchKit'
    coreNo.osx.frameworks = 'SystemConfiguration', 'WebKit'
    coreNo.tvos.frameworks = 'SystemConfiguration', 'UIKit'

    coreNo.ios.vendored_frameworks = base_dir + 'Source/Core/' + no_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreNo.tvos.vendored_frameworks = base_dir + 'Source/Base/' + no_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreNo.osx.vendored_frameworks = base_dir + 'Source/Base/' + no_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    coreNo.watchos.vendored_frameworks = base_dir + 'Source/Base/' + no_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    
    coreNo.ios.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Core/**/*'}
    coreNo.watchos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    coreNo.tvos.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
    coreNo.osx.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Base' do |base|
    base.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    base.watchos.frameworks = 'WatchKit'
    base.osx.frameworks = 'SystemConfiguration', 'WebKit'
    base.tvos.frameworks = 'SystemConfiguration', 'UIKit'

    base.vendored_frameworks = base_dir + 'Source/Base/' + dynamic_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    base.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

  s.subspec 'Base_ATT' do |baseATT|
    baseATT.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit', 'AdSupport'
    baseATT.ios.weak_framework = 'AppTrackingTransparency'
    baseATT.watchos.frameworks = 'WatchKit'
    baseATT.osx.frameworks = 'SystemConfiguration', 'WebKit'
    baseATT.tvos.frameworks = 'SystemConfiguration', 'UIKit', 'AdSupport'
    baseATT.tvos.weak_framework = 'AppTrackingTransparency'

    baseATT.vendored_frameworks = base_dir + 'Source/Base/' + att_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    baseATT.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
  end

    s.subspec 'Base_NO_IDFA' do |baseNo|
    baseNo.ios.frameworks = 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'UIKit'
    baseNo.watchos.frameworks = 'WatchKit'
    baseNo.osx.frameworks = 'SystemConfiguration', 'WebKit'
    baseNo.tvos.frameworks = 'SystemConfiguration', 'UIKit'

    baseNo.vendored_frameworks = base_dir + 'Source/Base/' + no_IDFA_dir + 'SensorsAnalyticsSDK.xcframework'
    baseNo.resource_bundle = { 'SensorsAnalyticsSDK' => 'SensorsAnalyticsSDK/Resources/Base/**/*'}
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
