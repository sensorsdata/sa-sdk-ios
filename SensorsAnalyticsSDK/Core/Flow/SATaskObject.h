//
// SATaskObject.h
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
#import "SANodeObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SATaskObject : NSObject

@property (nonatomic, copy) NSString *taskID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

@property (nonatomic, strong) NSArray<NSString *> *nodeIDs;

@property (nonatomic, strong) NSMutableArray<SANodeObject *> *nodes;

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dic;
- (instancetype)initWithTaskID:(NSString *)taskID name:(NSString *)name nodes:(NSArray<SANodeObject *> *)nodes;

/// 在任务重查询节点位置
///
/// 如果结果小于 0，则任务重不包含该节点
/// 
/// @param nodeID 节点 Id
/// @return 返回位置
- (NSInteger)indexOfNodeWithID:(NSString *)nodeID;

/// 任务中插入节点
///
/// 需要在 start flow 前插入，否则可能无效
/// 
/// @param node 需要插入的节点
/// @param index 插入位置
- (void)insertNode:(SANodeObject *)node atIndex:(NSUInteger)index;

+ (NSDictionary<NSString *, SATaskObject *> *)loadFromBundle:(NSBundle *)bundle;
+ (NSDictionary<NSString *, SATaskObject *> *)loadFromResources:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END
