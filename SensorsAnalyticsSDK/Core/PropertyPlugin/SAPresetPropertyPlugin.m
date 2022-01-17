//
// SAPresetPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/9/7.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAPresetPropertyPlugin.h"
#import "SAJSONUtil.h"
#import "SALog.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

//中国运营商 mcc 标识
static NSString* const SACarrierChinaMCC = @"460";

#pragma mark - device
/// 型号
static NSString * const kSAEventPresetPropertyPluginCarrier = @"$carrier";
/// 型号
static NSString * const kSAEventPresetPropertyPluginModel = @"$model";
/// 生产商
static NSString * const kSAEventPresetPropertyPluginManufacturer = @"$manufacturer";
/// 屏幕高
static NSString * const kSAEventPresetPropertyPluginScreenHeight = @"$screen_height";
/// 屏幕宽
static NSString * const kSAEventPresetPropertyPluginScreenWidth = @"$screen_width";

#pragma mark - os
/// 系统
static NSString * const kSAEventPresetPropertyPluginOS = @"$os";
/// 系统版本
static NSString * const kSAEventPresetPropertyPluginOSVersion = @"$os_version";

#pragma mark - app
/// 应用 ID
static NSString * const SAEventPresetPropertyPluginAppID = @"$app_id";
/// 应用名称
static NSString * const kSAEventPresetPropertyPluginAppName = @"$app_name";
/// 时区偏移量
static NSString * const kSAEventPresetPropertyPluginTimezoneOffset = @"$timezone_offset";

#pragma mark - lib
/// SDK 类型
NSString * const kSAEventPresetPropertyPluginLib = @"$lib";
/// SDK 版本
NSString * const kSAEventPresetPropertyPluginLibVersion = @"$lib_version";

@interface SAPresetPropertyPlugin ()

@property (nonatomic, copy) NSString *libVersion;

@end

@implementation SAPresetPropertyPlugin

- (instancetype)initWithLibVersion:(NSString *)libVersion {
    self = [super init];
    if (self) {
        _libVersion = libVersion;
    }
    return self;
}

- (SAPropertyPluginEventTypes)eventTypeFilter {
    return SAPropertyPluginEventTypeTrack | SAPropertyPluginEventTypeSignup | SAPropertyPluginEventTypeBind | SAPropertyPluginEventTypeUnbind;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (void)start {
    NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionary];
    properties[kSAEventPresetPropertyPluginModel] = [self deviceModel];
    properties[kSAEventPresetPropertyPluginManufacturer] = @"Apple";

#if TARGET_OS_IOS
    properties[kSAEventPresetPropertyPluginCarrier] = [self carrierName];
    properties[kSAEventPresetPropertyPluginOS] = @"iOS";
    properties[kSAEventPresetPropertyPluginOSVersion] = [[UIDevice currentDevice] systemVersion];
    properties[kSAEventPresetPropertyPluginLib] = @"iOS";

    CGSize size = [UIScreen mainScreen].bounds.size;
#elif TARGET_OS_OSX

    properties[kSAEventPresetPropertyPluginOS] = @"macOS";
    properties[kSAEventPresetPropertyPluginLib] = @"macOS";

    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    properties[kSAEventPresetPropertyPluginOSVersion] = systemVersion[@"ProductVersion"];

    CGSize size = [NSScreen mainScreen].frame.size;
#endif

    properties[SAEventPresetPropertyPluginAppID] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    properties[kSAEventPresetPropertyPluginAppName] = [self appName];

    properties[kSAEventPresetPropertyPluginScreenHeight] = @((NSInteger)size.height);
    properties[kSAEventPresetPropertyPluginScreenWidth] = @((NSInteger)size.width);

    properties[kSAEventPresetPropertyPluginLibVersion] = self.libVersion;
    // 计算时区偏移（保持和 JS 获取时区偏移的计算结果一致，这里首先获取分钟数，然后取反）
    NSInteger minutesOffsetGMT = - ([[NSTimeZone defaultTimeZone] secondsFromGMT] / 60);
    properties[kSAEventPresetPropertyPluginTimezoneOffset] = @(minutesOffsetGMT);

    self.properties = properties;
}

- (NSString *)deviceModel {
    NSString *result = nil;
    @try {
        NSString *hwName = @"hw.machine";
#if TARGET_OS_OSX
        hwName = @"hw.model";
#endif
        size_t size;
        sysctlbyname([hwName UTF8String], NULL, &size, NULL, 0);
        char answer[size];
        sysctlbyname([hwName UTF8String], answer, &size, NULL, 0);
        if (size) {
            result = @(answer);
        }
    } @catch (NSException *exception) {

    }
    return result;
}

- (NSString *)appName {
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (displayName.length > 0) {
        return displayName;
    }

    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName.length > 0) {
        return bundleName;
    }

    NSString *executableName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
    if (executableName) {
        return executableName;
    }

    return nil;
}

#if TARGET_OS_IOS
- (NSString *)carrierName API_UNAVAILABLE(macos) {
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
                    carrierName = @"中国移动";
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName = @"中国联通";
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName = @"中国电信";
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName = @"中国卫通";
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName = @"中国铁通";
                }
            } else if (countryCode && networkCode) { //国外运营商解析
                //加载当前 bundle
                NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
                //文件路径
                NSString *jsonPath = [sensorsBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                NSDictionary *dicAllMcc = [SAJSONUtil JSONObjectWithData:jsonData];
                if (dicAllMcc) {
                    NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                    carrierName = dicAllMcc[mccMncKey];
                }
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return carrierName;
}
#endif


@end
