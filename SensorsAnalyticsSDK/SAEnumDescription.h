//
//  SAEnumDescription.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SATypeDescription.h"

@interface SAEnumDescription : SATypeDescription

@property (nonatomic, assign, getter=isFlagsSet, readonly) BOOL flagSet;
@property (nonatomic, copy, readonly) NSString *baseType;

- (NSArray *)allValues; // array of NSNumber instances

@end
