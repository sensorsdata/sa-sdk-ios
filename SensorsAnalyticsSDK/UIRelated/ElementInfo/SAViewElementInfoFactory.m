//
// SAViewElementInfoFactory.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAViewElementInfoFactory.h"

@implementation SAViewElementInfoFactory

+ (SAViewElementInfo *)elementInfoWithView:(UIView *)view {
    NSString *viewType = NSStringFromClass(view.class);
    if ([viewType isEqualToString:@"_UIInterfaceActionCustomViewRepresentationView"] ||
        [viewType isEqualToString:@"_UIAlertControllerCollectionViewCell"]) {
        return [[SAAlertElementInfo alloc] initWithView:view];
    }
    
    // _UIContextMenuActionView 为 iOS 13 UIMenu 最终响应事件的控件类型;
    // _UIContextMenuActionsListCell 为 iOS 14 UIMenu 最终响应事件的控件类型;
    if ([viewType isEqualToString:@"_UIContextMenuActionView"] ||
        [viewType isEqualToString:@"_UIContextMenuActionsListCell"]) {
        return [[SAMenuElementInfo alloc] initWithView:view];
    }
    return [[SAViewElementInfo alloc] initWithView:view];
}

@end
