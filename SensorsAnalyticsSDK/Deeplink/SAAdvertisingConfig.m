//
// SAAdvertisingConfig.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/16.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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
    config.enableRemarketing = self.enableRemarketing;
    config.wakeupUrl = self.wakeupUrl;
    return config;
}

@end
