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
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SAModuleType) {
    SAModuleTypeLocation,
    SAModuleTypeChannelMatch,
};

@interface SAModuleManager : NSObject <SAOpenURLProtocol>

+ (instancetype)sharedInstance;

- (nullable id<SAModuleProtocol>)managerForModuleType:(SAModuleType)type;

- (void)setEnable:(BOOL)enable forModuleType:(SAModuleType)type;

@end

#pragma mark -

@interface SAModuleManager (Property)

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@interface SAModuleManager (ChannelMatch) <SAChannelMatchModuleProtocol>
@end

NS_ASSUME_NONNULL_END
