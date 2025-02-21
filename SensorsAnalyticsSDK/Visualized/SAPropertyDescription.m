//
// SAPropertyDescription.m
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SALog.h"
#import "SAPropertyDescription.h"

@implementation SAPropertySelectorParameterDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSParameterAssert(dictionary[@"name"] != nil);
    NSParameterAssert(dictionary[@"type"] != nil);

    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
        _type = [dictionary[@"type"] copy];
        _key = dictionary[@"key"] ?: _name;
    }

    return self;
}

@end

@implementation SAPropertySelectorDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSParameterAssert(dictionary[@"selector"] != nil);
//   NSParameterAssert(dictionary[@"parameters"] != nil);

    self = [super init];
    if (self) {
        _selectorName = [dictionary[@"selector"] copy];
        
        _returnType = [dictionary[@"result"][@"type"] copy]; // optional
    }

    return self;
}

@end

@interface SAPropertyDescription ()

@end

@implementation SAPropertyDescription

+ (NSValueTransformer *)valueTransformerForType:(NSString *)typeName {
    for (NSString *toTypeName in @[@"NSDictionary", @"NSNumber", @"NSString"]) {
        NSString *toTransformerName = [NSString stringWithFormat:@"SA%@To%@ValueTransformer", typeName, toTypeName];
        NSValueTransformer *toTransformer = [NSValueTransformer valueTransformerForName:toTransformerName];
        if (toTransformer) {
            return toTransformer;
        }
    }

    // Default to pass-through.
    return [NSValueTransformer valueTransformerForName:@"SAPassThroughValueTransformer"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSParameterAssert(dictionary[@"name"] != nil);

    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy]; // required
        _readonly = [dictionary[@"readonly"] boolValue]; // Optional
        _key = dictionary[@"key"] ?: _name;

        NSDictionary *get = dictionary[@"get"];
        if (get == nil) {
            NSParameterAssert(dictionary[@"type"] != nil);
            get = @{
                @"selector" : _name,
                @"result" : @{
                        @"type" : dictionary[@"type"],
                        @"name" : @"value"
                }
            };
        }

        _getSelectorDescription = [[SAPropertySelectorDescription alloc] initWithDictionary:get];

        BOOL useKVC = (dictionary[@"use_kvc"] == nil ? YES : [dictionary[@"use_kvc"] boolValue]);
        _useKeyValueCoding = useKVC;
    }

    return self;
}

- (NSString *)type {
    return _getSelectorDescription.returnType;
}

- (NSValueTransformer *)valueTransformer {
    return [[self class] valueTransformerForType:self.type];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p name='%@' type='%@' %@>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.type, self.readonly ? @"readonly" : @""];
}

@end
