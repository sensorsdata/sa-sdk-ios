//
// SAVisualizedViewPathProperty.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/28.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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


#import <Foundation/Foundation.h>

// 可视化全埋点上传页面信息相关协议
@protocol SAVisualizedViewPathProperty <NSObject>

@optional
/// 当前元素，前端是否渲染成可交互
@property (nonatomic, assign, readonly) BOOL sensorsdata_enableAppClick;

/// 当前元素的有效内容
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementValidContent;

/// 元素子视图
@property (nonatomic, copy, readonly) NSArray *sensorsdata_subElements;

/// 当前元素的相对路径
@property (nonatomic, copy, readonly) NSString *sensorsdata_elementPath;

/// 相对 keywindow 的坐标
@property (nonatomic, assign, readonly) CGRect sensorsdata_frame;

/// 是否为 Web 元素
@property (nonatomic, assign) BOOL sensorsdata_isFromWeb;
@end


@protocol SAVisualizedExtensionProperty <NSObject>

@optional
/// 一个 view 可交互的有效尺寸
@property (nonatomic, assign, readonly) CGRect sensorsdata_validFrame;
@end
