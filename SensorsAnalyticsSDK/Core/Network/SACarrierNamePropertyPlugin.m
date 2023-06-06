//
// SACarrierNamePropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/9.
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

#import "SACarrierNamePropertyPlugin.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAConstants+Private.h"
#import "SALimitKeyManager.h"
#import "SAValidator.h"
#import "SACoreResources.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

/// 运营商名称
static NSString * const kSAEventPresetPropertyCarrier = @"$carrier";

@interface SACarrierNamePropertyPlugin()
@property (nonatomic, copy) NSString *carrierName;
@end
@implementation SACarrierNamePropertyPlugin

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#pragma mark - private method

- (instancetype)init {
    self = [super init];
    if (self) {
        _carrierName = [self buildCarrierName];
    }
    return self;
}

- (NSString *)buildCarrierName {
    NSString *carrierName = nil;
    @try {
        CTCarrier *carrier = [self buildCarrier];
        if (!carrier) {
            return carrierName;
        }

        NSString *networkCode = nil;
        if ([carrier respondsToSelector:@selector(mobileNetworkCode)]) {
            networkCode = [carrier mobileNetworkCode];
        }

        NSString *countryCode = nil;
        if ([carrier respondsToSelector:@selector(mobileCountryCode)]) {
            countryCode = [carrier mobileCountryCode];
        }

        if (![networkCode isKindOfClass:[NSString class]] || ![countryCode isKindOfClass:[NSString class]]) {
            return carrierName;
        }

        // iOS16.4 开始，mobileCountryCode 和 mobileNetworkCode 返回固定值 65535，且无法解析运营商名称，参考 https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-16_4-release-notes
        carrierName = [self carrierNameWithNetworkCode:networkCode AndCountryCode:countryCode];

    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    } @finally {
        return carrierName;
    }
}

- (NSString *)carrierNameWithNetworkCode:(NSString *)networkCode AndCountryCode:(NSString *)countryCode {
    NSString *carrierName = nil;
    // 中国运营商 mcc 标识
    NSString *carrierChinaMCC = @"460";
    // 国外运营商
    if (![countryCode isEqualToString:carrierChinaMCC]) {
        NSDictionary *mcc = [SACoreResources mcc];
        if (mcc) {
            NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
            carrierName = mcc[mccMncKey];
            return carrierName;
        }
    }
    //中国移动
    if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
        carrierName = SALocalizedString(@"SAPresetPropertyCarrierMobile");
        return carrierName;
    }
    //中国联通
    if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
        carrierName = SALocalizedString(@"SAPresetPropertyCarrierUnicom");
        return carrierName;
    }
    //中国电信
    if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
        carrierName = SALocalizedString(@"SAPresetPropertyCarrierTelecom");
        return carrierName;
    }
    //中国卫通
    if ([networkCode isEqualToString:@"04"]) {
        carrierName = SALocalizedString(@"SAPresetPropertyCarrierSatellite");
        return carrierName;
    }
    //中国铁通
    if ([networkCode isEqualToString:@"20"]) {
        carrierName = SALocalizedString(@"SAPresetPropertyCarrierTietong");
        return carrierName;
    }
    return carrierName;
}

- (CTCarrier *)buildCarrier {
    CTCarrier *carrier = nil;
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];

#ifdef __IPHONE_12_0
    if (@available(iOS 12.1, *)) {
        // 排序
        NSArray *carrierKeysArray = [networkInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
        carrier = networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
        if (![carrier respondsToSelector:@selector(mobileNetworkCode)] || !carrier.mobileNetworkCode) {
            carrier = networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
        }
    }
#endif
    if (!carrier && [networkInfo respondsToSelector:@selector(subscriberCellularProvider)]) {
        carrier = networkInfo.subscriberCellularProvider;
    }
    return carrier;
}

#endif

#pragma mark - SAPropertyPlugin method

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    NSString *carrier = [SALimitKeyManager carrier];
    if ([SAValidator isValidString:carrier]) {
        return @{kSAEventPresetPropertyCarrier: carrier};
    }
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    props[kSAEventPresetPropertyCarrier] = self.carrierName;
    return [props copy];
}

@end
