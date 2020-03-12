//
//  SAObjectSerializerContext.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAObjectSerializerContext.h"

@implementation SAObjectSerializerContext {
    NSMutableSet *_visitedObjects;
    NSMutableArray *_unvisitedObjects;
    NSMutableDictionary *_serializedObjects;
    NSInteger _levelIndex; // 保存当前元素层级序号
}

- (instancetype)initWithRootObject:(id)object {
    self = [super init];
    if (self) {
        _visitedObjects = [NSMutableSet set];
        _unvisitedObjects = [NSMutableArray arrayWithObject:object];
        _serializedObjects = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (BOOL)hasUnvisitedObjects {
    return [_unvisitedObjects count] > 0;
}

- (void)enqueueUnvisitedObject:(NSObject *)object {
    if (object && ![_unvisitedObjects containsObject:object]) {
        [_unvisitedObjects insertObject:object atIndex:0];
    }
}

- (void)enqueueUnvisitedObjects:(NSArray *)objects {
    if (!objects) {
        return;
    }
    NSMutableArray *newObjects = [NSMutableArray array];
    for (NSObject *object in objects) {
        if (![_unvisitedObjects containsObject:object]) {
            [newObjects addObject:object];
        }
    }
    [_unvisitedObjects insertObjects:newObjects atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newObjects.count)]];
}

- (NSObject *)dequeueUnvisitedObject {
    NSObject *object = [_unvisitedObjects firstObject];
    [_unvisitedObjects removeObject:object];
    _levelIndex ++;
    return object;
}

- (void)addVisitedObject:(NSObject *)object {
    if (object) {
        [_visitedObjects addObject:object];
    }
}

- (BOOL)isVisitedObject:(NSObject *)object {
    return [_visitedObjects containsObject:object];
}

- (void)addSerializedObject:(NSDictionary *)serializedObject {
    if (serializedObject[@"id"]) {
        _serializedObjects[serializedObject[@"id"]] = serializedObject;
    }
}

- (NSArray *)allSerializedObjects {
    return [_serializedObjects allValues];
}

- (NSInteger)currentLevelIndex {
    return _levelIndex;
}
@end
