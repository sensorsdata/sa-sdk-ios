//
//  SATypeDescription.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SATypeDescription.h"

@implementation SATypeDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
    }

    return self;
}

@end
