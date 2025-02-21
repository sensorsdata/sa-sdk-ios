//
// SensorsAnalyticsSDK+DebugMode.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+DebugMode.h"
#import "SADebugModeManager.h"

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

@implementation SensorsAnalyticsSDK (DebugMode)

- (void)showDebugInfoView:(BOOL)show {
    [[SADebugModeManager defaultManager] setShowDebugAlertView:show];
}

- (SensorsAnalyticsDebugMode)debugMode {
    return self.configOptions.debugMode;
}

@end
