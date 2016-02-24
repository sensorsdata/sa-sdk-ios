//
//  SATypeDescription.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

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
