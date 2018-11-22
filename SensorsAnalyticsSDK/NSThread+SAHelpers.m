//
//  NSThread+SAHelpers.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/6/26.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "NSThread+SAHelpers.h"

@implementation NSThread (MPHelpers)
+ (void)sa_safelyRunOnMainThreadSync:(void (^)(void))block {
    if ([self isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
@end
