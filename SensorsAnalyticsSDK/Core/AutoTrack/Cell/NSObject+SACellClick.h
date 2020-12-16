//
// NSObject+SACellClick.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2020/11/5.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SACellClick)

/// 用于记录创建子类时的原始父类名称
@property (nonatomic, copy, nullable) NSString *sensorsdata_className;

/// 注册一个操作,在对象释放时调用; 重复调用该方法时,只有第一次调用时的 block 生效
/// @param deallocBlock 操作
- (void)sensorsdata_registerDeallocBlock:(void (^)(void))deallocBlock;

@end

NS_ASSUME_NONNULL_END
