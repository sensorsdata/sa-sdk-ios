//
// SABaseStoreManager.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAStorePlugin.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SAStoreManagerCompletion)(id _Nullable object);

@interface SABaseStoreManager : NSObject

/// 注册存储插件
/// - Parameter plugin: 需要注册的插件对象
- (void)registerStorePlugin:(id<SAStorePlugin>)plugin;

/// 注销存储插件
/// - Parameter cla: 待注销的插件类型 Class
- (void)unregisterStorePluginWithPluginClass:(Class)cla;

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
