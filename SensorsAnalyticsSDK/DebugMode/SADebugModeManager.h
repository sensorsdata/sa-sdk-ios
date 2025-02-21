//
// SADebugModeManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAModuleProtocol.h"
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (DebugModePrivate)

@property (nonatomic, assign) SensorsAnalyticsDebugMode debugMode;

@end

@interface SADebugModeManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SADebugModeModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;
@property (nonatomic) BOOL showDebugAlertView;

@end

NS_ASSUME_NONNULL_END
