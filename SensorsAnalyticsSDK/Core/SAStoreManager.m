//
// SAStoreManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAStoreManager.h"

@interface SABaseStoreManager (SAPrivate)

@property (nonatomic, strong) NSMutableArray<id<SAStorePlugin>> *plugins;

@end

@implementation SAStoreManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAStoreManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAStoreManager alloc] init];
    });
    return manager;
}

- (BOOL)isRegisteredCustomStorePlugin {
    // 默认情况下 SDK 只有两个存储插件
    return self.plugins.count > 2;
}

@end
