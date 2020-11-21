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

@interface SARemoteConfigManager ()

@property (atomic, strong) SARemoteConfigOperator *operator;

@end

@implementation SARemoteConfigManager

#pragma mark - Life Cycle

+ (void)startWithRemoteConfigOptions:(SARemoteConfigOptions *)options {
    [SARemoteConfigManager sharedInstance].operator = [[SARemoteConfigCommonOperator alloc] initWithRemoteConfigOptions:options];
}

+ (instancetype)sharedInstance {
    static SARemoteConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SARemoteConfigManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Public

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

- (void)cancelRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.operator cancelRequestRemoteConfig];
    }
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.operator respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.operator retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isBlackListContainsEvent:(nullable NSString *)event {
    return [self.operator isBlackListContainsEvent:event];
}

- (void)handleRemoteConfigURL:(NSURL *)url {
    SARemoteConfigOptions *options = self.operator.options;
    SARemoteConfigModel *model = self.operator.model;
    
    self.operator = [[SARemoteConfigCheckOperator alloc] initWithRemoteConfigOptions:options remoteConfigModel:model];
    
    if ([self.operator respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        [self.operator handleRemoteConfigURL:url];
    }
}

- (BOOL)isRemoteConfigURL:(NSURL *)url {
    return [url.host isEqualToString:kSASchemeHostRemoteConfig];
}

- (BOOL)canHandleURL:(NSURL *)url {
    return [self isRemoteConfigURL:url];
}

#pragma mark - Getters and Setters

- (BOOL)isDisableSDK {
    return self.operator.isDisableSDK;
}

- (NSInteger)autoTrackMode {
    return self.operator.autoTrackMode;
}

@end
