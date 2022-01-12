//
// SADelegateProxyObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/11/12.
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

@interface SADelegateProxyObject : NSObject

@property (nonatomic, strong) Class delegateISA;
@property (nonatomic, strong, nullable) Class kvoClass;

@property (nonatomic, copy, nullable) NSString *sensorsClassName;
@property (nonatomic, strong, readonly, nullable) Class sensorsClass;

/// 记录 - class 方法的返回值
@property (nonatomic, strong) id delegateClass;

/// 移除 KVO 后, 重新 hook 时使用的 Proxy
@property (nonatomic, strong) Class delegateProxy;

/// 当前代理对象已 hook 的方法集合
@property (nonatomic, copy) NSMutableSet *selectors;

- (instancetype)initWithDelegate:(id)delegate proxy:(id)proxy;

- (void)removeKVO;

@end

@interface SADelegateProxyObject (Utils)

+ (BOOL)isKVOClass:(Class _Nullable)cls;

@end

NS_ASSUME_NONNULL_END
