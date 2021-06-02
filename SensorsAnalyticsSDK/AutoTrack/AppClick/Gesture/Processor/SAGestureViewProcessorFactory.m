//
// SAGestureViewProcessorFactory.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/19.
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
