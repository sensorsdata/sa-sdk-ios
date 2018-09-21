//
//  NSThread+SAHelpers.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/6/26.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSThread (MPHelpers)
+ (void)sa_safelyRunOnMainThreadSync:(void (^)(void))block;
@end
