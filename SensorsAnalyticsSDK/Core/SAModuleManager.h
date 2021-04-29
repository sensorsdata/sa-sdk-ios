//
// SAModuleManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/14.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SAModuleType) {
    SAModuleTypeLocation,
    SAModuleTypeChannelMatch,
    SAModuleTypeVisualized,
    SAModuleTypeEncrypt,
    SAModuleTypeDeviceOrientation,
    SAModuleTypeReactNative,
    SAModuleTypeAppPush,
};

@interface SAModuleManager : NSObject <SAOpenURLProtocol>

+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions debugMode:(SensorsAnalyticsDebugMode)debugMode;

+ (instancetype)sharedInstance;

/// 当前 SDK 中是否包含特定类型的模块
/// @param type 需要判断的模块类型
/// @return 是否包含
- (BOOL)contains:(SAModuleType)type;

/// 通过模块类型获取模块的管理类
/// @param type 模块类型
/// @return 模块管理类
- (nullable id<SAModuleProtocol>)managerForModuleType:(SAModuleType)type;

/// 开启或关闭某种类型的模块
/// @param enable 开启或者关闭
/// @param type 模块类型
- (void)setEnable:(BOOL)enable forModuleType:(SAModuleType)type;

@end

#pragma mark -

@interface SAModuleManager (Property)

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@interface SAModuleManager (ChannelMatch) <SAChannelMatchModuleProtocol>
@end

#pragma mark -
@interface SAModuleManager (Visualized) <SAVisualizedModuleProtocol>

/// 是否正在连接
@property (nonatomic, assign, readonly, getter=isConnecting) BOOL connecting;

@end

@interface SAModuleManager (DebugMode) <SADebugModeModuleProtocol>

@end

#pragma mark -
@interface SAModuleManager (Encrypt) <SAEncryptModuleProtocol>

@property (nonatomic, strong, readonly) id<SAEncryptModuleProtocol> encryptManager;

@end

@interface SAModuleManager (PushClick) <SAAppPushModuleProtocol>

@end

#pragma mark -

@interface SAModuleManager (Gesture) <SAGestureModuleProtocol>

@property (nonatomic, strong, readonly) id<SAGestureModuleProtocol> gestureManager;

@end

#pragma mark -

@interface SAModuleManager (Deeplink) <SADeeplinkModuleProtocol>

@end

NS_ASSUME_NONNULL_END
