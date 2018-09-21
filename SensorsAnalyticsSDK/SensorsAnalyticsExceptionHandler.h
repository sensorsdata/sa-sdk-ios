//
//  SensorsAnalyticsExceptionHandler.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/5/26.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SensorsAnalyticsSDK;

@interface SensorsAnalyticsExceptionHandler : NSObject

+ (instancetype)sharedHandler;
- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance;

@end
