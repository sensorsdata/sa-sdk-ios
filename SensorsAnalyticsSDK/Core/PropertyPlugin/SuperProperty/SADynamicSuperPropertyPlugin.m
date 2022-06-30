//
// SADynamicSuperPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/4/24.
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

#import "SADynamicSuperPropertyPlugin.h"
#import "SASuperPropertyPlugin.h"
#import "SAPropertyPluginManager.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAReadWriteLock.h"
#import "SAPropertyValidator.h"

@interface SADynamicSuperPropertyPlugin ()
/// 动态公共属性回调
@property (nonatomic, copy) SADynamicSuperPropertyBlock dynamicSuperPropertyBlock;
/// 动态公共属性
@property (atomic, strong) NSDictionary *dynamicSuperProperties;

@property (nonatomic, strong) SAReadWriteLock *dynamicSuperPropertiesLock;
@end


@implementation SADynamicSuperPropertyPlugin

+ (SADynamicSuperPropertyPlugin *)sharedDynamicSuperPropertyPlugin {
    static SADynamicSuperPropertyPlugin *propertyPlugin;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertyPlugin = [[SADynamicSuperPropertyPlugin alloc] init];
    });
    return propertyPlugin;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *dynamicSuperPropertiesLockLabel = [NSString stringWithFormat:@"com.sensorsdata.dynamicSuperPropertiesLock.%p", self];
        _dynamicSuperPropertiesLock = [[SAReadWriteLock alloc] initWithQueueLabel:dynamicSuperPropertiesLockLabel];
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    return [self.dynamicSuperProperties copy];
}

#pragma mark - dynamicSuperProperties
- (void)registerDynamicSuperPropertiesBlock:(SADynamicSuperPropertyBlock)dynamicSuperPropertiesBlock {
    [self.dynamicSuperPropertiesLock writeWithBlock:^{
        self.dynamicSuperPropertyBlock = dynamicSuperPropertiesBlock;
    }];
}

- (void)buildDynamicSuperProperties {
    [self.dynamicSuperPropertiesLock readWithBlock:^id _Nonnull{
        if (!self.dynamicSuperPropertyBlock) {
            return nil;
        }

        NSDictionary *dynamicProperties = self.dynamicSuperPropertyBlock();
        self.dynamicSuperProperties = [SAPropertyValidator validProperties:[dynamicProperties copy]];

        // 如果包含仅大小写不同的 key 注销对应 superProperties
        dispatch_async(SensorsAnalyticsSDK.sdkInstance.serialQueue, ^{
            SASuperPropertyPlugin *superPropertyPlugin = (SASuperPropertyPlugin *)[SAPropertyPluginManager.sharedInstance pluginsWithPluginClass:SASuperPropertyPlugin.class];
            if (superPropertyPlugin) {
                [superPropertyPlugin unregisterSameLetterSuperProperties:self.dynamicSuperProperties];
            }
        });

        return nil;
    }];
}

@end
