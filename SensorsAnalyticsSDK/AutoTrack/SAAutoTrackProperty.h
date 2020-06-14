//
//  SAAutoTrackProperty.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/23.
//  Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
    

#import <Foundation/Foundation.h>

@protocol SAAutoTrackViewControllerProperty <NSObject>
@property (nonatomic, readonly) BOOL sensorsdata_isIgnored;
@property (nonatomic, copy, readonly) NSString *sensorsdata_screenName;
@property (nonatomic, copy, readonly) NSString *sensorsdata_title;
@end

#pragma mark -
@protocol SAAutoTrackViewProperty <NSObject>
@property (nonatomic, readonly) BOOL sensorsdata_isIgnored;

@property (nonatomic, copy, readonly) NSString *sensorsdata_elementType;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementContent;
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementId;

/// 元素位置，UISegmentedControl 中返回选中的 index，
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPosition;

/// 获取 view 所在的 viewController，或者当前的 viewController
@property (nonatomic, readonly) UIViewController<SAAutoTrackViewControllerProperty> *sensorsdata_viewController;
@end

#pragma mark -
@protocol SAAutoTrackCellProperty <SAAutoTrackViewProperty>
- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath;
- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath;

- (NSString *)sensorsdata_similarPathWithIndexPath:(NSIndexPath *)indexPath;
/// 遍历查找 cell 所在的 indexPath
@property (nonatomic, strong, readonly) NSIndexPath *sensorsdata_IndexPath;
@end



#pragma mark -
@protocol SAAutoTrackViewPathProperty <NSObject>

/// $AppClick 某个元素的相对路径，拼接 $element_path，用于可视化全埋点
@property (nonatomic, copy, readonly) NSString *sensorsdata_itemPath;

/// $AppClick 某个元素的相对路径，拼接 $element_selector，用于点击图
@property (nonatomic, copy, readonly) NSString *sensorsdata_heatMapPath;

@optional
/// 元素相似路径，可能包含 [-]
@property (nonatomic, copy, readonly) NSString *sensorsdata_similarPath;
@end
