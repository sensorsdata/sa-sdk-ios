//
// SARemoteConfigManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/5.
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

#import "SARemoteConfigManager.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAModuleManager.h"
#import "SALog.h"

@interface SARemoteConfigManager ()

@property (atomic, strong) SARemoteConfigOperator *operator;

@end

@implementation SARemoteConfigManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kSAAppLifecycleStateWillChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SAModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        self.operator = [[SARemoteConfigCommonOperator alloc] initWithConfigOptions:self.configOptions remoteConfigModel:nil];
    } else {
        self.operator = nil;
    }
}

#pragma mark - AppLifecycle

- (void)appLifecycleStateWillChange:(NSNotification *)sender {
    if (!self.isEnable) {
        return;
    }

    NSDictionary *userInfo = sender.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    SAAppLifecycleState oldState = [userInfo[kSAAppLifecycleOldStateKey] integerValue];

    // 冷启动
    if (oldState == SAAppLifecycleStateInit && newState == SAAppLifecycleStateStart) {
        [self tryToRequestRemoteConfig];
        return;
    }

    // 热启动
    if (oldState != SAAppLifecycleStateInit && newState == SAAppLifecycleStateStart) {
        [self enableLocalRemoteConfig];
        [self tryToRequestRemoteConfig];
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        [self cancelRequestRemoteConfig];
    }
}

#pragma mark - SAOpenURLProtocol

- (BOOL)canHandleURL:(NSURL *)url {
    return self.isEnable && [url.host isEqualToString:@"sensorsdataremoteconfig"];
}

- (BOOL)handleURL:(NSURL *)url {
    // 打开 log 用于调试
    [SensorsAnalyticsSDK.sdkInstance enableLog:YES];

    [self cancelRequestRemoteConfig];

    if (![self.operator isKindOfClass:[SARemoteConfigCheckOperator class]]) {
        SARemoteConfigModel *model = self.operator.model;
        self.operator = [[SARemoteConfigCheckOperator alloc] initWithConfigOptions:self.configOptions remoteConfigModel:model];
    }

    if ([self.operator respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        return [self.operator handleRemoteConfigURL:url];
    }

    return NO;
}

- (void)cancelRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.operator cancelRequestRemoteConfig];
    }
}

- (void)enableLocalRemoteConfig {
    if ([self.operator respondsToSelector:@selector(enableLocalRemoteConfig)]) {
        [self.operator enableLocalRemoteConfig];
    }
}

- (void)tryToRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(tryToRequestRemoteConfig)]) {
        [self.operator tryToRequestRemoteConfig];
    }
}

#pragma mark - SARemoteConfigModuleProtocol

- (BOOL)isDisableSDK {
    return self.operator.isDisableSDK;
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.operator respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.operator retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isIgnoreEventObject:(SABaseEventObject *)obj {
    if (obj.isIgnoreRemoteConfig) {
        return NO;
    }

    if (self.operator.isDisableSDK) {
        SALogDebug(@"【remote config】SDK is disabled");
        return YES;
    }

    if ([self.operator isBlackListContainsEvent:obj.event]) {
        SALogDebug(@"【remote config】 %@ is ignored by remote config", obj.event);
        return YES;
    }

    return NO;
}

@end
