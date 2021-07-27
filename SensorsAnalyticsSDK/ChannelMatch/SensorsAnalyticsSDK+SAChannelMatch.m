//
// SensorsAnalyticsSDK+SAChannelMatch.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/7/2.
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

#import "SensorsAnalyticsSDK+SAChannelMatch.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SATrackEventObject.h"
#import "SAModuleManager.h"
#import "SASuperProperty.h"

// 激活事件
static NSString * const kSAEventNameAppInstall = @"$AppInstall";

@implementation SensorsAnalyticsSDK (SAChannelMatch)

- (void)trackChannelEvent:(NSString *)event {
    [self trackChannelEvent:event properties:nil];
}

- (void)trackChannelEvent:(NSString *)event properties:(nullable NSDictionary *)propertyDict {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:event];
    object.dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        [SAModuleManager.sharedInstance trackChannelWithEventObject:object properties:propertyDict];
    });
}

- (void)trackAppInstall {
    [self trackAppInstallWithProperties:nil];
}

- (void)trackAppInstallWithProperties:(NSDictionary *)properties {
    [self trackAppInstallWithProperties:properties disableCallback:NO];
}

- (void)trackAppInstallWithProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    [SAModuleManager.sharedInstance trackAppInstall:kSAEventNameAppInstall properties:properties disableCallback:disableCallback];
}

- (void)trackInstallation:(NSString *)event {
    [self trackInstallation:event withProperties:nil disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self trackInstallation:event withProperties:propertyDict disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    [SAModuleManager.sharedInstance trackAppInstall:event properties:properties disableCallback:disableCallback];
}

@end
