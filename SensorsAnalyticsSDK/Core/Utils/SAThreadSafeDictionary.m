//
// SAThreadSafeDictionary.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/9/14.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAThreadSafeDictionary.h"

@interface SAThreadSafeDictionary ()

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation SAThreadSafeDictionary

#pragma mark - init

+ (SAThreadSafeDictionary *)dictionary {
    return [[SAThreadSafeDictionary alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dictionary = [NSMutableDictionary dictionary];
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (id)objectForKeyedSubscript:(id)key {
    [self.lock lock];
    id result = [self.dictionary objectForKeyedSubscript:key];
    [self.lock unlock];
    return result;
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    [self.lock lock];
    [self.dictionary setObject:obj forKeyedSubscript:key];
    [self.lock unlock];
}

- (NSArray *)allKeys {
    [self.lock lock];
    NSArray *result = [self.dictionary allKeys];
    [self.lock unlock];
    return result;
}

- (NSArray *)allValues {
    [self.lock lock];
    NSArray *result = [self.dictionary allValues];
    [self.lock unlock];
    return result;
}

- (void)removeObjectForKey:(id)key {
    [self.lock lock];
    [self.dictionary removeObjectForKey:key];
    [self.lock unlock];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id _Nonnull, id _Nonnull, BOOL * _Nonnull))block {
    [self.lock lock];
    [self.dictionary enumerateKeysAndObjectsUsingBlock:block];
    [self.lock unlock];
}

@end
