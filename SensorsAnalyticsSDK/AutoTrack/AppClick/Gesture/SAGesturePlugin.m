//
// SAGesturePlugin.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
