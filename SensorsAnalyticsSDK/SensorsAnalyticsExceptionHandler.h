//
//  SensorsAnalyticsExceptionHandler.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/5/26.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SensorsAnalyticsSDK;

@interface SensorsAnalyticsExceptionHandler : NSObject

+ (instancetype)sharedHandler;
- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance;

@end
