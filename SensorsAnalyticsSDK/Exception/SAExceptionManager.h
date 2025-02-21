//
// SAExceptionManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/6/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAExceptionManager : NSObject <SAModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

@end

NS_ASSUME_NONNULL_END
