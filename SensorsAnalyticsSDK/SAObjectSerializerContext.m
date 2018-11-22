//
//  SAObjectSerializerContext.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAObjectSerializerContext.h"

@implementation SAObjectSerializerContext {
    NSMutableSet *_visitedObjects;
    NSMutableSet *_unvisitedObjects;
    NSMutableDictionary *_serializedObjects;
}

- (instancetype)initWithRootObject:(id)object {
    self = [super init];
    if (self) {
        _visitedObjects = [NSMutableSet set];
        _unvisitedObjects = [NSMutableSet setWithObject:object];
        _serializedObjects = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (BOOL)hasUnvisitedObjects {
    return [_unvisitedObjects count] > 0;
}

- (void)enqueueUnvisitedObject:(NSObject *)object {
    NSParameterAssert(object != nil);

    [_unvisitedObjects addObject:object];
}

- (NSObject *)dequeueUnvisitedObject {
    NSObject *object = [_unvisitedObjects anyObject];
    [_unvisitedObjects removeObject:object];

    return object;
}

- (void)addVisitedObject:(NSObject *)object {
    NSParameterAssert(object != nil);

    [_visitedObjects addObject:object];
}

- (BOOL)isVisitedObject:(NSObject *)object {
    return object && [_visitedObjects containsObject:object];
}

- (void)addSerializedObject:(NSDictionary *)serializedObject {
    NSParameterAssert(serializedObject[@"id"] != nil);
    _serializedObjects[serializedObject[@"id"]] = serializedObject;
}

- (NSArray *)allSerializedObjects {
    return [_serializedObjects allValues];
}

@end
