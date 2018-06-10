//
//  SAClassDescription.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "SAClassDescription.h"
#import "SAPropertyDescription.h"

@implementation SADelegateInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _selectorName = dictionary[@"selector"];
    }
    return self;
}

@end

@implementation SAClassDescription {
    NSArray *_propertyDescriptions;
    NSArray *_delegateInfos;
}

- (instancetype)initWithSuperclassDescription:(SAClassDescription *)superclassDescription
                                   dictionary:(NSDictionary *)dictionary {
    self = [super initWithDictionary:dictionary];
    if (self) {
        _superclassDescription = superclassDescription;

        NSMutableArray *propertyDescriptions = [NSMutableArray array];
        for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
            [propertyDescriptions addObject:[[SAPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }

        _propertyDescriptions = [propertyDescriptions copy];

        NSMutableArray *delegateInfos = [NSMutableArray array];
        for (NSDictionary *delegateInfoDictionary in dictionary[@"delegateImplements"]) {
            [delegateInfos addObject:[[SADelegateInfo alloc] initWithDictionary:delegateInfoDictionary]];
        }
        _delegateInfos = [delegateInfos copy];
    }

    return self;
}

- (NSArray *)propertyDescriptions {
    NSMutableDictionary *allPropertyDescriptions = [[NSMutableDictionary alloc] init];

    SAClassDescription *description = self;
    while (description)
    {
        for (SAPropertyDescription *propertyDescription in description->_propertyDescriptions) {
            if (!allPropertyDescriptions[propertyDescription.name]) {
                allPropertyDescriptions[propertyDescription.name] = propertyDescription;
            }
        }
        description = description.superclassDescription;
    }

    return [allPropertyDescriptions allValues];
}

- (BOOL)isDescriptionForKindOfClass:(Class)class {
    return [self.name isEqualToString:NSStringFromClass(class)] && [self.superclassDescription isDescriptionForKindOfClass:[class superclass]];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end
