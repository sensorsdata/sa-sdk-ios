//
// SAAdvertisingConfig.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAAdvertisingConfig.h"

@interface SAAdvertisingConfig ()

/// secret key to encrypt events send to sensors advertising
@property (nonatomic, copy) SASecretKey *adsSecretKey;

/// server url to upload ads related events
@property (nonatomic, copy) NSString *adsServerUrl;

/// ads related events, using event name, such as ["$AppInstall","$AppStart"]
@property (nonatomic, copy) NSArray<NSString*> *adsEvents;

@end

@implementation SAAdvertisingConfig

- (nonnull instancetype)initWithServerUrl:(nonnull NSString *)serverUrl events:(nonnull NSArray<NSString *> *)events secretKey:(nullable SASecretKey *)key {
    if (self = [super init]) {
        _adsServerUrl = serverUrl;
        _adsEvents = events;
        _adsSecretKey = key;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    SAAdvertisingConfig *config = [[[self class] allocWithZone:zone] init];
    config.adsServerUrl = self.adsServerUrl;
    config.adsEvents = self.adsEvents;
    config.adsSecretKey = self.adsSecretKey;
    return config;
}

@end
