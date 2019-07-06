//
//  SAAutoTrackProperty.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/23.
//  Copyright © 2019 Sensors Data Inc. All rights reserved.
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
/// 只在 UISegmentedControl 中返回选中的 index，其他类型返回 nil
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPosition;

/// 获取 view 所在的 viewController，或者当前的 viewController
@property (nonatomic, readonly) UIViewController<SAAutoTrackViewControllerProperty> *sensorsdata_viewController;
@end

#pragma mark -
@protocol SAAutoTrackCellProperty <SAAutoTrackViewProperty>
- (NSString *)sensorsdata_elementPositionWithIndexPath:(NSIndexPath *)indexPath;
- (NSString *)sensorsdata_itemPathWithIndexPath:(NSIndexPath *)indexPath;
@end



#pragma mark -
@protocol SAAutoTrackViewPathProperty <NSObject>
@property (nonatomic, copy, readonly) NSString *sensorsdata_itemPath;
@end
