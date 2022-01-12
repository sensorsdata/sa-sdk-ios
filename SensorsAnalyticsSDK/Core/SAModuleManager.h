//
// SAModuleManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/8/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAModuleManager : NSObject <SAOpenURLProtocol>

+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions;

+ (instancetype)sharedInstance;

- (BOOL)isDisableSDK;

/// 关闭所有的模块功能
- (void)disableAllModules;

/// 更新数据接收地址
/// @param serverURL 新的数据接收地址
- (void)updateServerURL:(NSString *)serverURL;
@end

#pragma mark -

@interface SAModuleManager (Property)

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@interface SAModuleManager (ChannelMatch) <SAChannelMatchModuleProtocol>
@end

#pragma mark -

@interface SAModuleManager (DebugMode) <SADebugModeModuleProtocol>

@end

#pragma mark -
@interface SAModuleManager (Encrypt) <SAEncryptModuleProtocol>

@property (nonatomic, strong, readonly) id<SAEncryptModuleProtocol> encryptManager;

@end

#pragma mark -

@interface SAModuleManager (Deeplink) <SADeeplinkModuleProtocol>

@end

#pragma mark -

@interface SAModuleManager (AutoTrack) <SAAutoTrackModuleProtocol>

@end

#pragma mark -

@interface SAModuleManager (Visualized) <SAVisualizedModuleProtocol>

@end

#pragma mark -

@interface SAModuleManager (JavaScriptBridge) <SAJavaScriptBridgeModuleProtocol>

@end

@interface SAModuleManager (RemoteConfig) <SARemoteConfigModuleProtocol>

@end

NS_ASSUME_NONNULL_END
