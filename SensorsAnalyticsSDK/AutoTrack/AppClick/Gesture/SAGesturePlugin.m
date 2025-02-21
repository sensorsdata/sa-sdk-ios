//
// SAGesturePlugin.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAGesturePlugin.h"
#import "SASwizzle.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import <UIKit/UIKit.h>

static NSString *const kSAEventTrackerPluginType = @"AppClick+UIGestureRecognizer";

@implementation SAGesturePlugin

- (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod];
    });
    self.enable = YES;
}

- (void)uninstall {
    self.enable = NO;
}

- (NSString *)type {
    return kSAEventTrackerPluginType;
}

- (void)swizzleMethod {
    // Gesture
    [UIGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                               withMethod:@selector(sensorsdata_initWithTarget:action:)
                                    error:NULL];
    [UIGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                               withMethod:@selector(sensorsdata_addTarget:action:)
                                    error:NULL];
    [UIGestureRecognizer sa_swizzleMethod:@selector(removeTarget:action:)
                               withMethod:@selector(sensorsdata_removeTarget:action:)
                                    error:NULL];
}

@end
