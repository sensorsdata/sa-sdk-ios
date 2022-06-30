//
// SAFlowObject.h
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
#import "SATaskObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAFlowObject : NSObject

@property (nonatomic, copy) NSString *flowID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *taskIDs;
@property (nonatomic, strong) NSArray<SATaskObject *> *tasks;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithFlowID:(NSString *)flowID name:(NSString *)name tasks:(NSArray<SATaskObject *> *)tasks;
- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dic;

- (nullable SATaskObject *)taskForID:(NSString *)taskID;

+ (NSDictionary<NSString *, SAFlowObject *> *)loadFromBundle:(NSBundle *)bundle;
@end

NS_ASSUME_NONNULL_END
