//
// SAPresetProperty.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/12.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#include <sys/sysctl.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "SAPresetProperty.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SACommonUtility.h"
#import "SALog.h"
#import "SAFileStore.h"
#import "SADateFormatter.h"
#import "SADeviceOrientationManager.h"
#import "SALocationManager.h"
#import "SAValidator.h"

//中国运营商 mcc 标识
static NSString* const SACarrierChinaMCC = @"460";

#pragma mark - device
/// 设备 ID
NSString * const SAEventPresetPropertyDeviceID = @"$device_id";
/// 运营商
static NSString * const SAEventPresetPropertyCarrier = @"$carrier";
/// 型号
static NSString * const SAEventPresetPropertyModel = @"$model";
/// 生产商
static NSString * const SAEventPresetPropertyManufacturer = @"$manufacturer";
/// 屏幕高
static NSString * const SAEventPresetPropertyScreenHeight = @"$screen_height";
/// 屏幕宽
static NSString * const SAEventPresetPropertyScreenWidth = @"$screen_width";

#pragma mark - os
/// 系统
static NSString * const SAEventPresetPropertyOS = @"$os";
/// 系统版本
static NSString * const SAEventPresetPropertyOSVersion = @"$os_version";

#pragma mark - app
/// 应用版本
NSString * const SAEventPresetPropertyAppVersion = @"$app_version";
/// 应用 ID
static NSString * const SAEventPresetPropertyAppID = @"$app_id";
/// 应用名称
static NSString * const SAEventPresetPropertyAppName = @"$app_name";
/// 时区偏移量
static NSString * const SAEventPresetPropertyTimezoneOffset = @"$timezone_offset";

#pragma mark - state
/// 网络类型
NSString * const SAEventPresetPropertyNetworkType = @"$network_type";
/// 是否 WI-FI
NSString * const SAEventPresetPropertyWifi = @"$wifi";
/// 是否首日
NSString * const SAEventPresetPropertyIsFirstDay = @"$is_first_day";
/// 应用程序状态
static NSString * const SAEventPresetPropertyAppState = @"$app_state";

#pragma mark - lib
/// SDK 类型
NSString * const SAEventPresetPropertyLib = @"$lib";
/// SDK 方法
NSString * const SAEventPresetPropertyLibMethod = @"$lib_method";
/// SDK 版本
NSString * const SAEventPresetPropertyLibVersion = @"$lib_version";
/// SDK 版本
NSString * const SAEventPresetPropertyLibDetail = @"$lib_detail";

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
static NSString * const SAEventPresetPropertyScreenOrientation = @"$screen_orientation";
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
static NSString * const SAEventPresetPropertyLatitude = @"$latitude";
static NSString * const SAEventPresetPropertyLongitude = @"$longitude";
#endif

#pragma mark -

@interface SAPresetProperty ()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableDictionary *automaticProperties;
@property (nonatomic, copy) NSString *firstDay;
@property (nonatomic, copy) NSString *libVersion;

@end

@implementation SAPresetProperty

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue libVersion:(NSString *)libVersion {
    self = [super init];
    if (self) {
        _queue = queue;
        
        dispatch_async(self.queue, ^{
            self.libVersion = libVersion;
            [self unarchiveFirstDay];
        });
    }
    return self;
}

#pragma mark – Public Methods

- (NSMutableDictionary *)libPropertiesWithMethod:(NSString *)method {
    NSMutableDictionary *libProperties = [NSMutableDictionary dictionary];
    libProperties[SAEventPresetPropertyLib] = self.automaticProperties[SAEventPresetPropertyLib];
    libProperties[SAEventPresetPropertyLibVersion] = self.automaticProperties[SAEventPresetPropertyLibVersion];
    libProperties[SAEventPresetPropertyAppVersion] = self.automaticProperties[SAEventPresetPropertyAppVersion];
    if ([SAValidator isValidString:method]) {
        libProperties[SAEventPresetPropertyLibMethod] = method;
    }
    return libProperties;
}

- (BOOL)isFirstDay {
    __block BOOL isFirstDay = NO;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        NSString *current = [dateFormatter stringFromDate:[NSDate date]];
        isFirstDay = [self.firstDay isEqualToString:current];
    });
    return isFirstDay;
}

- (NSDictionary *)currentNetworkProperties {
    NSString *networkType = [SACommonUtility currentNetworkStatus];

    NSMutableDictionary *networkProperties = [NSMutableDictionary dictionary];
    networkProperties[SAEventPresetPropertyNetworkType] = networkType;
    networkProperties[SAEventPresetPropertyWifi] = @([networkType isEqualToString:@"WIFI"]);
    return networkProperties;
}

- (NSDictionary *)currentPresetProperties {
    NSMutableDictionary *presetProperties = [NSMutableDictionary dictionary];
    [presetProperties addEntriesFromDictionary:self.automaticProperties];
    [presetProperties addEntriesFromDictionary:[self currentNetworkProperties]];
    presetProperties[SAEventPresetPropertyIsFirstDay] = @([self isFirstDay]);
    return presetProperties;
}

- (NSString *)appVersion {
    return self.automaticProperties[SAEventPresetPropertyAppVersion];
}

- (NSString *)deviceID {
    return self.automaticProperties[SAEventPresetPropertyDeviceID];
}

- (NSDictionary *)presetPropertiesOfTrackType:(BOOL)isLaunchedPassively
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
                            orientationConfig:(SADeviceOrientationConfig *)orientationConfig
#endif
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
                               locationConfig:(SAGPSLocationConfig *)locationConfig
#endif
{
    NSMutableDictionary *presetPropertiesOfTrackType = [NSMutableDictionary dictionary];
    // 是否首日访问
    presetPropertiesOfTrackType[SAEventPresetPropertyIsFirstDay] = @([self isFirstDay]);
    // 是否被动启动
    if (isLaunchedPassively) {
        presetPropertiesOfTrackType[SAEventPresetPropertyAppState] = @"background";
    }
    // 采集设备方向
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
    if (orientationConfig.enableTrackScreenOrientation && [SAValidator isValidString:orientationConfig.deviceOrientation]) {
        presetPropertiesOfTrackType[SAEventPresetPropertyScreenOrientation] = orientationConfig.deviceOrientation;
    }
#endif
    // 采集地理位置信息
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
    if (locationConfig.enableGPSLocation && CLLocationCoordinate2DIsValid(locationConfig.coordinate)) {
        NSInteger latitude = locationConfig.coordinate.latitude * pow(10, 6);
        NSInteger longitude = locationConfig.coordinate.longitude * pow(10, 6);
        presetPropertiesOfTrackType[SAEventPresetPropertyLatitude] = @(latitude);
        presetPropertiesOfTrackType[SAEventPresetPropertyLongitude] = @(longitude);
    }
#endif
    
    return presetPropertiesOfTrackType;
}

#pragma mark – Private Methods

- (void)unarchiveFirstDay {
    self.firstDay = [SAFileStore unarchiveWithFileName:@"first_day"];
    if (!self.firstDay) {
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
        [SAFileStore archiveWithFileName:@"first_day" value:self.firstDay];
    }
}

+ (NSString *)deviceModel {
    NSString *results = nil;
    @try {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char answer[size];
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        if (size) {
            results = @(answer);
        } else {
            SALogError(@"Failed fetch hw.machine from sysctl.");
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return results;
}

+ (NSString *)carrierName {
    NSString *carrierName = nil;
    @try {
        CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = nil;
        
#ifdef __IPHONE_12_0
        if (@available(iOS 12.1, *)) {
            // 排序
            NSArray *carrierKeysArray = [telephonyInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
            carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
            if (!carrier.mobileNetworkCode) {
                carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
            }
        }
#endif
        if (!carrier) {
            carrier = telephonyInfo.subscriberCellularProvider;
        }
        if (carrier != nil) {
            NSString *networkCode = [carrier mobileNetworkCode];
            NSString *countryCode = [carrier mobileCountryCode];
            
            //中国运营商
            if (countryCode && [countryCode isEqualToString:SACarrierChinaMCC] && networkCode) {
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName= @"中国移动";
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName= @"中国联通";
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName= @"中国电信";
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName= @"中国卫通";
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName= @"中国铁通";
                }
            } else if (countryCode && networkCode) { //国外运营商解析
                //加载当前 bundle
                NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
                //文件路径
                NSString *jsonPath = [sensorsBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                if (jsonData) {
                    NSDictionary *dicAllMcc =  [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
                    if (dicAllMcc) {
                        NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                        carrierName = dicAllMcc[mccMncKey];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return carrierName;
}

+ (NSString *)appName {
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (displayName) {
        return displayName;
    }
    
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName) {
        return bundleName;
    }
    
    NSString *executableName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
    if (executableName) {
        return executableName;
    }
    
    return nil;
}

#pragma mark – Getters and Setters

- (NSMutableDictionary *)automaticProperties {
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        if (!_automaticProperties) {
            _automaticProperties = [NSMutableDictionary dictionary];
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID
            _automaticProperties[SAEventPresetPropertyDeviceID] = [SAIdentifier uniqueHardwareId];
#endif
            _automaticProperties[SAEventPresetPropertyCarrier] = [SAPresetProperty carrierName];
            _automaticProperties[SAEventPresetPropertyModel] = [SAPresetProperty deviceModel];
            _automaticProperties[SAEventPresetPropertyManufacturer] = @"Apple";
            CGSize size = [UIScreen mainScreen].bounds.size;
            _automaticProperties[SAEventPresetPropertyScreenHeight] = @((NSInteger)size.height);
            _automaticProperties[SAEventPresetPropertyScreenWidth] = @((NSInteger)size.width);
            _automaticProperties[SAEventPresetPropertyOS] = @"iOS";
            _automaticProperties[SAEventPresetPropertyOSVersion] = [[UIDevice currentDevice] systemVersion];
            _automaticProperties[SAEventPresetPropertyAppID] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
            _automaticProperties[SAEventPresetPropertyAppName] = [SAPresetProperty appName];
            _automaticProperties[SAEventPresetPropertyAppVersion] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            _automaticProperties[SAEventPresetPropertyLib] = @"iOS";
            _automaticProperties[SAEventPresetPropertyLibVersion] = self.libVersion;
            // 计算时区偏移（保持和 JS 获取时区偏移的计算结果一致，这里首先获取分钟数，然后取反）
            NSInteger minutesOffsetGMT = - ([[NSTimeZone defaultTimeZone] secondsFromGMT] / 60);
            _automaticProperties[SAEventPresetPropertyTimezoneOffset] = @(minutesOffsetGMT);
        }
    });
    return _automaticProperties;
}

@end
