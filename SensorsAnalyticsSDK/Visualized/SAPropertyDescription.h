//
// SAPropertyDescription.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAObjectSerializerContext;

@interface SAPropertySelectorParameterDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *type;
// 上传页面属性的 key
@property (nonatomic, readonly) NSString *key;

@end

@interface SAPropertySelectorDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *selectorName;
@property (nonatomic, readonly) NSString *returnType;

@end

@interface SAPropertyDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) BOOL readonly;

@property (nonatomic, readonly) BOOL useKeyValueCoding;

@property (nonatomic, readonly) NSString *name;

// 上传页面属性的 key
@property (nonatomic, readonly) NSString *key;

@property (nonatomic, readonly) SAPropertySelectorDescription *getSelectorDescription;

- (NSValueTransformer *)valueTransformer;

@end
