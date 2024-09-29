//
// SABaseStoreManager.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SABaseStoreManager.h"

static const char * kSASerialQueueLabel = "com.sensorsdata.serialQueue.StoreManager";

@interface SABaseStoreManager ()

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@property (nonatomic, strong) NSMutableArray<id<SAStorePlugin>> *plugins;

@end

@implementation SABaseStoreManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [NSMutableArray array];
    }
    return self;
}

- (dispatch_queue_t)serialQueue {
    static dispatch_once_t onceToken;
    static dispatch_queue_t serialQueue;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create(kSASerialQueueLabel, DISPATCH_QUEUE_SERIAL);
    });
    return serialQueue;
}

- (NSString *)storeKeyWithPlugin:(id<SAStorePlugin>)plugin key:(NSString *)key {
    return [NSString stringWithFormat:@"%@%@", plugin.type, key];
}

- (BOOL)isMatchedWithPlugin:(id<SAStorePlugin>)plugin key:(NSString *)key {
    SEL sel = NSSelectorFromString(@"storeKeys");
    if (![plugin respondsToSelector:sel]) {
        return NO;
    }
    NSArray *(*imp)(id, SEL) = (NSArray *(*)(id, SEL))[(NSObject *)plugin methodForSelector:sel];
    NSArray *storeKeys = imp(plugin, sel);
    return [storeKeys containsObject:key];
}

- (BOOL)isRegisteredCustomStorePlugin {
    return NO;
}

- (id)objForKey:(NSString *)key {
    for (NSInteger index = 0; index < self.plugins.count; index++) {
        id<SAStorePlugin> plugin = self.plugins[index];
        NSString *storeKey = [self storeKeyWithPlugin:self.plugins[index] key:key];

        id result = [plugin objectForKey:storeKey];
        if (result) {
            // 当有注册自定义存储插件时，做数据迁移
            if ([self isRegisteredCustomStorePlugin] && index != 0) {
                id<SAStorePlugin> firstPlugin = self.plugins.firstObject;
                // 自定义存储插件，设置忽略历史数据
                if ([firstPlugin respondsToSelector:@selector(isIgnoreOldData)] && [firstPlugin isIgnoreOldData]) {
                    return nil;
                }

                NSString *firstKey = [self storeKeyWithPlugin:firstPlugin key:key];
                [firstPlugin setObject:result forKey:firstKey];

                [plugin removeObjectForKey:storeKey];
            }
            return result;
        }
    }
    return nil;
}


#pragma mark - public

- (void)registerStorePlugin:(id<SAStorePlugin>)plugin {
    NSAssert(plugin.type.length > 0, @"The store plugin's type must return a not empty string!");
    dispatch_async(self.serialQueue, ^{
        [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<SAStorePlugin>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([plugin.type isEqualToString:obj.type]) {
                [self.plugins removeObjectAtIndex:idx];
            } else if ([plugin respondsToSelector:@selector(upgradeWithOldPlugin:)]){
                [plugin upgradeWithOldPlugin:obj];
            }
        }];
        [self.plugins insertObject:plugin atIndex:0];
    });
}

- (void)unregisterStorePluginWithPluginClass:(Class)cla {
    if (!cla) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<SAStorePlugin>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:cla]) {
                [self.plugins removeObject:obj];
                *stop = YES;
            }
        }];
    });
}

#pragma mark - get

- (id)objectForKey:(NSString *)key {
    const char *chars = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    if (chars && strcmp(chars, kSASerialQueueLabel) == 0) {
        return [self objForKey:key];
    } else {
        __block id object = nil;
        dispatch_sync(self.serialQueue, ^{
            object = [self objForKey:key];
        });
        return object;
    }
}

- (void)objectForKey:(NSString *)key completion:(SAStoreManagerCompletion)completion {
    dispatch_async(self.serialQueue, ^{
        completion([self objForKey:key]);
    });
}

- (nullable NSString *)stringForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSString.class]) {
        return obj;
    }
    if ([obj isKindOfClass:NSNumber.class]) {
        return [obj stringValue];
    }
    return nil;
}

- (nullable NSArray *)arrayForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSArray.class]) {
        return obj;
    }
    return nil;
}

- (nullable NSDictionary *)dictionaryForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSDictionary.class]) {
        return obj;
    }
    return nil;
}

- (nullable NSData *)dataForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSData.class]) {
        return obj;
    }
    return nil;
}

- (NSInteger)integerForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj integerValue];
    }
    return 0;
}

- (float)floatForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj floatValue];
    }
    return 0;
}

- (double)doubleForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj doubleValue];
    }
    return 0;
}

- (BOOL)boolForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj boolValue];
    }
    return NO;
}

#pragma mark - set

- (void)setObject:(id)object forKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{
        if (![self isRegisteredCustomStorePlugin]) {
            for (id<SAStorePlugin> plugin in self.plugins) {
                // 当没有自定义存储插件时，使用插件 key 匹配
                if ([self isMatchedWithPlugin:plugin key:key]) {
                    NSString *storeKey = [self storeKeyWithPlugin:plugin key:key];
                    return [plugin setObject:object forKey:storeKey];
                }
            }
        }

        /* 使用默认存储插件（最后注册的插件）
            1. 当注册自定义存储插件
            2. key 匹配失败
         */
        id<SAStorePlugin> firstPlugin = self.plugins.firstObject;
        NSString *storeKey = [self storeKeyWithPlugin:firstPlugin key:key];
        [firstPlugin setObject:object forKey:storeKey];
        
        // 移除其他插件旧数据
        [self.plugins enumerateObjectsUsingBlock:^(id<SAStorePlugin>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == 0) {
                return;
            }
            [obj removeObjectForKey:[self storeKeyWithPlugin:obj key:key]];
        }];
    });
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

#pragma mark - remove

- (void)removeObjectForKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{
        for (id<SAStorePlugin> obj in self.plugins) {
            [obj removeObjectForKey:[self storeKeyWithPlugin:obj key:key]];
        }
    });
}

@end
