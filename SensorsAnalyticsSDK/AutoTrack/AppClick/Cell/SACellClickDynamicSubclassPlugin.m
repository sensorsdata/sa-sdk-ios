//
// SANewCellClickPlugin.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SACellClickDynamicSubclassPlugin.h"
#import "SASwizzle.h"
#import <UIKit/UIKit.h>

static NSString *const kSAEventTrackerPluginType = @"AppClick+ScrollView";

@implementation SACellClickDynamicSubclassPlugin

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
    SEL selector = NSSelectorFromString(@"sensorsdata_setDelegate:");
    [UITableView sa_swizzleMethod:@selector(setDelegate:)
                       withMethod:selector
                            error:NULL];
    [UICollectionView sa_swizzleMethod:@selector(setDelegate:)
                            withMethod:selector
                                 error:NULL];
}

@end
