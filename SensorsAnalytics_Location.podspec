Pod::Spec.new do |s|
  s.name         = "SensorsAnalytics_Location"
  s.version      = "5.0.6"
  s.summary      = "The official iOS SDK of Sensors Analytics Location."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" }
  s.license = {
    :type => 'Commercial',
    :file => 'LICENSE'
  }
  s.author = { "caojiang" => "caojiang@sensorsdata.cn" }
  s.ios.deployment_target = '9.0'
  s.default_subspec = 'Core'
  s.frameworks = 'UIKit', 'CoreLocation'
  s.dependency 'SensorsAnalyticsSDK', '>=5.0.0'

  # 限制 CocoaPods 版本
  s.cocoapods_version = '>= 1.12.0'

  s.subspec 'Core' do |c|
    c.vendored_frameworks = 'SensorsAnalytics_Location/Source/SensorsAnalytics_Location.xcframework'
    c.resource_bundle = { 'SensorsAnalytics_Location' => 'SensorsAnalytics_Location/Resources/**/*'}
  end

end