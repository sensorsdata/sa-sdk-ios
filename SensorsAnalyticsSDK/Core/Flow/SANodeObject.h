//
// SANodeObject.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
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
#import "SAInterceptor.h"
#import "SAFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SANodeObject : NSObject

@property (nonatomic, copy) NSString *nodeID;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *interceptorClassName;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic;
- (instancetype)initWithNodeID:(NSString *)nodeID name:(NSString *)name interceptor:(SAInterceptor *)interceptor;

@property (nonatomic, strong, readonly) SAInterceptor *interceptor;

+ (NSDictionary<NSString *, SANodeObject *> *)loadFromBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
