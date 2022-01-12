//
// SAThreadSafeDictionary.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/9/14.
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
