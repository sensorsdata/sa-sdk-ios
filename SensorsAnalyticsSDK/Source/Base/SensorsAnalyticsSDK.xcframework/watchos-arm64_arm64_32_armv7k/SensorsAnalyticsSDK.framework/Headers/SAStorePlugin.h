//
// SAStorePlugin.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/12/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAStorePlugin <NSObject>

- (NSString *)type;

- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)value forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

@optional
/// 可以用于将一些重要特殊的 key 进行迁移操作
///
/// SDK 会在注册新插件时，调用该方法
/// 该方法可能会调用多次，每次调用会传入之前注册的插件
///
/// @param oldPlugin 旧插件
- (void)upgradeWithOldPlugin:(id<SAStorePlugin>)oldPlugin;

/// 注册自定义存储插件，是否忽略历史旧数据
///
/// 如果未实现，则默认不忽略，即迁移历史数据迁移
/// 如果要求忽略旧插件的本地存储历史数据，则实现该接口，并返回 YES
///
/// @return 是否忽略
- (BOOL)isIgnoreOldData;
@end

NS_ASSUME_NONNULL_END
