//
// SAGestureTargetActionModel.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/8.
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

NS_ASSUME_NONNULL_BEGIN

@interface SAGestureTargetActionModel : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign, readonly) BOOL isValid;

- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (BOOL)isEqualToTarget:(id)target andAction:(SEL)action;

/// 查询数组中是否存在一个对象的 target-action 和 参数的 target-action 相同
/// 由于在 dealloc 中使用了 weak 引用,会触发崩溃,因此没有通过重写 isEqual: 方式实现该逻辑
/// @param target target
/// @param action action
/// @param models 待查询的数组
+ (SAGestureTargetActionModel * _Nullable)containsObjectWithTarget:(id)target andAction:(SEL)action fromModels:(NSArray <SAGestureTargetActionModel *>*)models;

/// 从数组中过滤出有效的 target-action 对象
/// @param models 有效的对象数组
+ (NSArray <SAGestureTargetActionModel *>*)filterValidModelsFrom:(NSArray <SAGestureTargetActionModel *>*)models;

@end

NS_ASSUME_NONNULL_END
