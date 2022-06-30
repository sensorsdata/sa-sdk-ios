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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

/// 运营商名称
static NSString * const kSAEventPresetPropertyCarrier = @"$carrier";

@interface SACarrierNamePropertyPlugin()
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
#endif
@end
@implementation SACarrierNamePropertyPlugin

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#pragma mark - private method
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
        _networkInfo = [SACarrierNamePropertyPlugin sharedNetworkInfo];
    }
    return self;
}

- (void)dealloc {
    self.networkInfo = nil;
}

- (NSString *)currentCarrierName {
    NSString *carrierName = nil;

    @try {
        CTCarrier *carrier = nil;

#ifdef __IPHONE_12_0
        if (@available(iOS 12.1, *)) {
            // 排序
            NSArray *carrierKeysArray = [self.networkInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
            carrier = self.networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
            if (!carrier.mobileNetworkCode) {
                carrier = self.networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
            }
        }
#endif
        if (!carrier) {
            carrier = self.networkInfo.subscriberCellularProvider;
        }
        if (carrier != nil) {
            NSString *networkCode = [carrier mobileNetworkCode];
            NSString *countryCode = [carrier mobileCountryCode];

            // 中国运营商 mcc 标识
            NSString *carrierChinaMCC = @"460";

            //中国运营商
            if (countryCode && [countryCode isEqualToString:carrierChinaMCC] && networkCode) {
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName = SALocalizedString(@"SAPresetPropertyCarrierMobile");
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName = SALocalizedString(@"SAPresetPropertyCarrierUnicom");
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName = SALocalizedString(@"SAPresetPropertyCarrierTelecom");
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName = SALocalizedString(@"SAPresetPropertyCarrierSatellite");
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName = SALocalizedString(@"SAPresetPropertyCarrierTietong");
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

#pragma mark - SAPropertyPlugin method

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    props[kSAEventPresetPropertyCarrier] = [self currentCarrierName];
#endif
    return [props copy];
}

@end
