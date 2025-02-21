//
// SAFlutterElementView.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlutterElementView.h"

@implementation SAFlutterElementView


- (instancetype)initWithSuperView:(UIView *)superView elementInfo:(NSDictionary *)elementInfo {
    self = [super initWithSuperView:superView elementInfo:elementInfo];
    if (self) {
        self.platform = @"flutter";
    }
    return self;
}

@end
