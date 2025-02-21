//
// UIViewController+SAInternalProperties.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+SAInternalProperties.h"
#import "SACommonUtility.h"
#import "UIView+SAElementContent.h"

@implementation UIViewController (SAInternalProperties)

- (NSString *)sensorsdata_screenName {
    return NSStringFromClass(self.class);
}

- (NSString *)sensorsdata_title {
    __block NSString *titleViewContent = nil;
    __block NSString *controllerTitle = nil;
    [SACommonUtility performBlockOnMainThread:^{
        titleViewContent = self.navigationItem.titleView.sensorsdata_elementContent;
        controllerTitle = self.navigationItem.title;
    }];
    if (titleViewContent.length > 0) {
        return titleViewContent;
    }

    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    return nil;
}

@end
