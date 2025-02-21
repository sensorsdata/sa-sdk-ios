//
// UIView+SAElementType.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAElementType.h"
#import "SAViewElementInfoFactory.h"


@implementation UIView (SAElementType)

- (NSString *)sensorsdata_elementType {
    SAViewElementInfo *elementInfo = [SAViewElementInfoFactory elementInfoWithView:self];
    return elementInfo.elementType;
}

@end


@implementation UIControl (SAElementType)

- (NSString *)sensorsdata_elementType {
    // UIBarButtonItem
    if (([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"])) {
        return @"UIBarButtonItem";
    }

    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        return @"UITabBarItem";
    }
    return NSStringFromClass(self.class);
}



@end
