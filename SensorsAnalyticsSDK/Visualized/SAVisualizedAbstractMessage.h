//
// SAVisualizedAbstractMessage.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/9/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SAVisualizedMessage.h"

@interface SAVisualizedAbstractMessage : NSObject <SAVisualizedMessage>

@property (nonatomic, copy, readonly) NSString *type;

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload;

- (instancetype)initWithType:(NSString *)type;
- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;
- (void)removePayloadObjectForKey:(NSString *)key;
- (NSDictionary *)payload;

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode;

@end
