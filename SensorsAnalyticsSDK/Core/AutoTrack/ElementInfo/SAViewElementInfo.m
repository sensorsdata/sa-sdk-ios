//
// SAViewElementInfo.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAViewElementInfo.h"
#import "SAModuleManager.h"

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

- (BOOL)isVisualView {
    if (!self.view.userInteractionEnabled || self.view.alpha <= 0.01 || self.view.isHidden) {
        return NO;
    }
    return [SAModuleManager.sharedInstance isGestureVisualView:self.view];
}

@end

#pragma mark - Alert Element Type
@implementation SAAlertElementInfo

- (NSString *)elementType {
#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    UIWindow *window = self.view.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = self.view.bounds.size.height;
        if (actionHeight > 50) {
            return NSStringFromClass(UIActionSheet.class);
        } else {
            return NSStringFromClass(UIAlertView.class);
        }
    } else {
        return NSStringFromClass(UIAlertController.class);
    }
#else
    return NSStringFromClass(UIAlertController.class);
#endif
}

- (BOOL)isSupportElementPosition {
    return NO;
}

- (BOOL)isVisualView {
    if (SAModuleManager.sharedInstance.gestureManager) {
        return YES;
    }
    return [super isVisualView];
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

- (BOOL)isVisualView {
    // 在 iOS 14 中, 应当圈选 UICollectionViewCell
    if ([self.view.superview isKindOfClass:UICollectionViewCell.class]) {
        return NO;
    }
    if (SAModuleManager.sharedInstance.gestureManager) {
        return YES;
    }
    return [super isVisualView];
}

@end
