//
// SABaseStoreManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/8.
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
#import "SAStorePlugin.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SAStoreManagerCompletion)(id _Nullable object);

@interface SABaseStoreManager : NSObject

- (void)registerStorePlugin:(id<SAStorePlugin>)plugin;

#pragma mark - get

- (nullable id)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key completion:(SAStoreManagerCompletion)completion;

- (nullable NSString *)stringForKey:(NSString *)key;
- (nullable NSArray *)arrayForKey:(NSString *)key;
- (nullable NSDictionary *)dictionaryForKey:(NSString *)key;
- (nullable NSData *)dataForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

#pragma mark - set

- (void)setObject:(nullable id)object forKey:(NSString *)key;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

#pragma mark - remove

- (void)removeObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
