//
// SAObject+SAConfigOptions.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAObject+SAConfigOptions.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SALog.h"
#import "SAModuleManager.h"
#if __has_include("SAConfigOptions+Encrypt.h")
#import "SAConfigOptions+Encrypt.h"
#endif

@implementation SADatabase (SAConfigOptions)

- (NSUInteger)maxCacheSize {
#ifdef DEBUG
    if (NSClassFromString(@"XCTestCase")) {
        return 10000;
    }
#endif
    return [SensorsAnalyticsSDK sdkInstance].configOptions.maxCacheSize;
}

@end
