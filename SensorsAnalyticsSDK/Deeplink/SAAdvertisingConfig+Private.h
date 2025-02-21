//
// SAAdvertisingConfig+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/8/17.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//


@interface SAAdvertisingConfig (SAAdvertisingConfigPrivate)

/// secret key to encrypt events send to sensors advertising
@property (nonatomic, copy) SASecretKey *adsSecretKey;

/// server url to upload ads related events
@property (nonatomic, copy) NSString *adsServerUrl;

/// ads related events, using event name, such as ["$AppInstall","$AppStart"]
@property (nonatomic, copy) NSArray<NSString*> *adsEvents;

@end
