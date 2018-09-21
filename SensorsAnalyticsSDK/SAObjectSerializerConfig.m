//
//  SAObjectSerializerConfig.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SAClassDescription.h"
#import "SAEnumDescription.h"
#import "SAObjectSerializerConfig.h"
#import "SATypeDescription.h"

@implementation SAObjectSerializerConfig {
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *classDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"classes"]) {
            NSString *superclassName = d[@"superclass"];
            SAClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            SAClassDescription *classDescription = [[SAClassDescription alloc] initWithSuperclassDescription:superclassDescription
                                                                                                  dictionary:d];

            classDescriptions[classDescription.name] = classDescription;
        }

        NSMutableDictionary *enumDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"enums"]) {
            SAEnumDescription *enumDescription = [[SAEnumDescription alloc] initWithDictionary:d];
            enumDescriptions[enumDescription.name] = enumDescription;
        }

        _classes = [classDescriptions copy];
        _enums = [enumDescriptions copy];
    }

    return self;
}

- (NSArray *)classDescriptions {
    return [_classes allValues];
}

- (SAEnumDescription *)enumWithName:(NSString *)name {
    return _enums[name];
}

- (SAClassDescription *)classWithName:(NSString *)name {
    return _classes[name];
}

- (SATypeDescription *)typeWithName:(NSString *)name {
    SAEnumDescription *enumDescription = [self enumWithName:name];
    if (enumDescription) {
        return enumDescription;
    }

    SAClassDescription *classDescription = [self classWithName:name];
    if (classDescription) {
        return classDescription;
    }

    return nil;
}

@end
