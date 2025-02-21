//
// SAGestureViewProcessorFactory.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAGestureViewProcessorFactory.h"

@implementation SAGestureViewProcessorFactory

+ (SAGeneralGestureViewProcessor *)processorWithGesture:(UIGestureRecognizer *)gesture {
    NSString *viewType = NSStringFromClass(gesture.view.class);
    if ([viewType isEqualToString:@"_UIAlertControllerView"]) {
        return [[SALegacyAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIAlertControllerInterfaceActionGroupView"]) {
        return [[SANewAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"UIInterfaceActionGroupView"]) {
        return [[SALegacyMenuGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIContextMenuActionsListView"]) {
        return [[SAMenuGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"UITableViewCellContentView"]) {
        return [[SATableCellGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([gesture.view.nextResponder isKindOfClass:UICollectionViewCell.class]) {
        return [[SACollectionCellGestureViewProcessor alloc] initWithGesture:gesture];
    }
    return [[SAGeneralGestureViewProcessor alloc] initWithGesture:gesture];
}

@end
