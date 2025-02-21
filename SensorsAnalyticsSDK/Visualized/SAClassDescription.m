//
// SAClassDescription.m
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SAClassDescription.h"
#import "SAPropertyDescription.h"

@implementation SAClassDescription {
    NSArray *_propertyDescriptions;
}

- (instancetype)initWithSuperclassDescription:(SAClassDescription *)superclassDescription
                                   dictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _superclassDescription = superclassDescription;
        _name = dictionary[@"name"];
        NSMutableArray *propertyDescriptions = [NSMutableArray array];
        for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
            [propertyDescriptions addObject:[[SAPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }

        _propertyDescriptions = [propertyDescriptions copy];
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
