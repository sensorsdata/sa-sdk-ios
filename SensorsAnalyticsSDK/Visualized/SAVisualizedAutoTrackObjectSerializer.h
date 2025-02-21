//
// SAObjectSerializer.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAClassDescription;
@class SAObjectSerializerConfig;
@class SAObjectIdentityProvider;

@interface SAVisualizedAutoTrackObjectSerializer : NSObject

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
               objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end
