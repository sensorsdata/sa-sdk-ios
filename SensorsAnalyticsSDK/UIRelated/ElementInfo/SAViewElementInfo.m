//
// SAViewElementInfo.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAViewElementInfo.h"

#pragma mark - View Element Type
@implementation SAViewElementInfo

- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (NSString *)elementType {
    return NSStringFromClass(self.view.class);
}

- (BOOL)isSupportElementPosition {
    return YES;
}

@end

#pragma mark - Alert Element Type
@implementation SAAlertElementInfo

- (NSString *)elementType {
    UIWindow *window = self.view.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = self.view.bounds.size.height;
        if (actionHeight > 50) {
            return @"UIActionSheet";
        } else {
            return @"UIAlertView";
        }
    } else {
        return NSStringFromClass(UIAlertController.class);
    }
}

- (BOOL)isSupportElementPosition {
    return NO;
}

@end

#pragma mark - Menu Element Type
@implementation SAMenuElementInfo

- (NSString *)elementType {
    return @"UIMenu";
}

- (BOOL)isSupportElementPosition {
    return NO;
}

@end
