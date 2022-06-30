//
// SANetworkInfoPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2022/3/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SANetworkInfoPropertyPlugin.h"
#import "SALog.h"
#import "SAJSONUtil.h"
#import "SAReachability.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

/// 网络类型
static NSString * const kSAEventPresetPropertyNetworkType = @"$network_type";
/// 是否 WI-FI
static NSString * const kSAEventPresetPropertyWifi = @"$wifi";


@interface SANetworkInfoPropertyPlugin ()

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
#endif

@end

@implementation SANetworkInfoPropertyPlugin

#pragma mark - private method
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

+ (CTTelephonyNetworkInfo *)sharedNetworkInfo {
    static CTTelephonyNetworkInfo *networkInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    return networkInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _networkInfo = [SANetworkInfoPropertyPlugin sharedNetworkInfo];
    }
    return self;
}

- (void)dealloc {
    self.networkInfo = nil;
}

- (SensorsAnalyticsNetworkType)networkTypeWWANOptionsWithString:(NSString *)networkTypeString {
    if ([@"2G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType2G;
    } else if ([@"3G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType3G;
    } else if ([@"4G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType4G;
#ifdef __IPHONE_14_1
    } else if ([@"5G" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType5G;
#endif
    } else if ([@"UNKNOWN" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkType4G;
    }
    return SensorsAnalyticsNetworkTypeNONE;
}

- (NSString *)networkTypeWWANString {
    if (![SAReachability sharedInstance].isReachableViaWWAN) {
        return @"NULL";
    }

    NSString *currentRadioAccessTechnology = nil;
#ifdef __IPHONE_12_0
    if (@available(iOS 12.1, *)) {
        currentRadioAccessTechnology = self.networkInfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
    }
#endif
    // 测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
    if (!currentRadioAccessTechnology) {
        currentRadioAccessTechnology = self.networkInfo.currentRadioAccessTechnology;
    }

    return [self networkStatusWithRadioAccessTechnology:currentRadioAccessTechnology];
}

- (NSString *)networkStatusWithRadioAccessTechnology:(NSString *)value {
    if ([value isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [value isEqualToString:CTRadioAccessTechnologyEdge]
        ) {
        return @"2G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyWCDMA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSDPA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSUPA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
               [value isEqualToString:CTRadioAccessTechnologyeHRPD]
               ) {
        return @"3G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyLTE]) {
        return @"4G";
    }

#ifdef __IPHONE_14_1
    else if (@available(iOS 14.1, *)) {
        if ([value isEqualToString:CTRadioAccessTechnologyNRNSA] ||
            [value isEqualToString:CTRadioAccessTechnologyNR]
            ) {
            return @"5G";
        }
    }
#endif
    return @"UNKNOWN";
}

#endif

- (NSString *)networkTypeString {
    NSString *networkTypeString = @"NULL";
    @try {
        if ([SAReachability sharedInstance].isReachableViaWiFi) {
            networkTypeString = @"WIFI";
        }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
        else {
            networkTypeString = [self networkTypeWWANString];
        }
#endif
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return networkTypeString;
}

#pragma mark - public method
/// 当前的网络类型
- (SensorsAnalyticsNetworkType)currentNetworkTypeOptions {
    NSString *networkTypeString = [self networkTypeString];

    if ([@"NULL" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkTypeNONE;
    } else if ([@"WIFI" isEqualToString:networkTypeString]) {
        return SensorsAnalyticsNetworkTypeWIFI;
    }

    SensorsAnalyticsNetworkType networkType = SensorsAnalyticsNetworkTypeNONE;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    networkType = [self networkTypeWWANOptionsWithString:networkTypeString];
#endif
    return networkType;
}

#pragma mark - PropertyPlugin
- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

/// 当前的网络属性
- (NSDictionary<NSString *,id> *)properties {
    NSString *networkType = [self networkTypeString];

    NSMutableDictionary *networkProperties = [NSMutableDictionary dictionary];
    networkProperties[kSAEventPresetPropertyNetworkType] = networkType;
    networkProperties[kSAEventPresetPropertyWifi] = @([networkType isEqualToString:@"WIFI"]);
    return networkProperties;
}

@end
