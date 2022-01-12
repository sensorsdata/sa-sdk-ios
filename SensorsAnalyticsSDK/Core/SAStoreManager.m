//
// SAStoreManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
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
