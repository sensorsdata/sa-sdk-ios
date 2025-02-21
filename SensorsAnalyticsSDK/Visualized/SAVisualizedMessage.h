//
// SAVisualizedMessage.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/9/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAVisualizedConnection;

@protocol SAVisualizedMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;

- (id)payloadObjectForKey:(NSString *)key;

- (void)removePayloadObjectForKey:(NSString *)key;

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode;

@optional
- (NSOperation *)responseCommandWithConnection:(SAVisualizedConnection *)connection;

@end
