//
// SARemoteConfigManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/11/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SARemoteConfigCommonOperator.h"
#import "SARemoteConfigCheckOperator.h"
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (RemoteConfigPrivate)

@property (nonatomic, assign) BOOL enableRemoteConfig;

@end

@interface SARemoteConfigManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SARemoteConfigModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

NS_ASSUME_NONNULL_END
