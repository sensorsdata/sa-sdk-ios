//
//  SAObjectSerializerContext.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAObjectSerializerContext : NSObject

- (instancetype)initWithRootObject:(id)object;

- (BOOL)hasUnvisitedObjects;

- (void)enqueueUnvisitedObject:(NSObject *)object;
- (NSObject *)dequeueUnvisitedObject;

- (void)addVisitedObject:(NSObject *)object;
- (BOOL)isVisitedObject:(NSObject *)object;

- (void)addSerializedObject:(NSDictionary *)serializedObject;
- (NSArray *)allSerializedObjects;

@end
