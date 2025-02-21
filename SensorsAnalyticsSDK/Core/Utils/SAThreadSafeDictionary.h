//
// SAThreadSafeDictionary.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/9/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface SAThreadSafeDictionary<KeyType, ObjectType> : NSObject

+ (SAThreadSafeDictionary *)dictionary;

@property (readonly, copy) NSArray<KeyType> *allKeys;
@property (readonly, copy) NSArray<ObjectType> *allValues;

- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;

- (void)removeObjectForKey:(KeyType)aKey;
- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
