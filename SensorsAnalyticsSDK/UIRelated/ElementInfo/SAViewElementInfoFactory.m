//
// SAViewElementInfoFactory.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/18.
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
