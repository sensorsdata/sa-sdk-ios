//
// NSObject+SAKeyValueObserver.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/2/23.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

@interface SAKVOObject : NSObject

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) NSValue *context;

- (instancetype)initWithKeyPath:(NSString *)keyPath context:(void *)context;

@end

@interface NSObject (SAKeyValueObserver)
//As a target, added observer infos
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <SAKVOObject *> *>*sensorsdata_KVO_observerInfos;
//As a observer, target infos
@property (nonatomic, strong) NSMutableDictionary *sensorsdata_KVO_targetInfos;

- (void)sensorsdata_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

//avoid crash for KVO
- (void)sensorsdata_dealloc;

/// observer mark
@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_KVO_observers;

/// target mark
@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_KVO_targets;

@end

NS_ASSUME_NONNULL_END
