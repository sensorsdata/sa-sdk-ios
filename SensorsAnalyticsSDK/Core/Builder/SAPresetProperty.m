//
// SAPresetProperty.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/12.
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

#import "SAPresetProperty.h"
#import "SAConstants+Private.h"
#import "SAIdentifier.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAReachability.h"
#import "SALog.h"
#import "SAStoreManager.h"
#import "SADateFormatter.h"
#import "SAValidator.h"
#import "SAModuleManager.h"
#import "SAJSONUtil.h"

#pragma mark - state
/// 网络类型
NSString * const kSAEventPresetPropertyNetworkType = @"$network_type";
/// 是否 WI-FI
NSString * const kSAEventPresetPropertyWifi = @"$wifi";
/// 是否首日
NSString * const kSAEventPresetPropertyIsFirstDay = @"$is_first_day";

#pragma mark -

@interface SAPresetProperty ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, copy) NSString *firstDay;

@end

@implementation SAPresetProperty

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        
        dispatch_async(self.queue, ^{
            [self unarchiveFirstDay];
        });
    }
    return self;
}

#pragma mark – Public Methods

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
    NSString *networkType = [SANetwork networkTypeString];

    NSMutableDictionary *networkProperties = [NSMutableDictionary dictionary];
    networkProperties[kSAEventPresetPropertyNetworkType] = networkType;
    networkProperties[kSAEventPresetPropertyWifi] = @([networkType isEqualToString:@"WIFI"]);
    return networkProperties;
}

- (NSDictionary *)currentPresetProperties {
    NSMutableDictionary *presetProperties = [NSMutableDictionary dictionary];
    [presetProperties addEntriesFromDictionary:[self currentNetworkProperties]];
    presetProperties[kSAEventPresetPropertyIsFirstDay] = @([self isFirstDay]);
    return presetProperties;
}

#pragma mark – Private Methods

- (void)unarchiveFirstDay {
    self.firstDay = [[SAStoreManager sharedInstance] objectForKey:@"first_day"];
    if (!self.firstDay) {
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
        [[SAStoreManager sharedInstance] setObject:self.firstDay forKey:@"first_day"];
    }
}

@end
