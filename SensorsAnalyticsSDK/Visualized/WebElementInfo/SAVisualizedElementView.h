//
// SAVisualizedElementView.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/27.
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAVisualizedElementView : UIView

- (instancetype)initWithSuperView:(UIView *)superView elementInfo:(NSDictionary *)elementInfo;

/// 元素内容
@property (nonatomic, copy) NSString *elementContent;

/// 页面标题
@property (nonatomic, copy) NSString *title;

/// 页面名称
@property (nonatomic, copy) NSString *screenName;

/// 元素 id
@property (nonatomic, copy) NSString *elementId;

/// 子元素 id 集合
@property (nonatomic, copy) NSArray<NSString *> *subElementIds;

/// 子元素集合
@property (nonatomic, copy) NSArray<SAVisualizedElementView *> *_Nullable subElements;

/// 是否可点击
@property (nonatomic, assign) BOOL enableAppClick;

/// 是否为列表
@property (nonatomic, assign) BOOL isListView;

/// 元素路径
///
/// H5 新版使用
@property (nonatomic, copy) NSString *elementPath;

/// 元素位置
@property (nonatomic, copy, nullable) NSString *elementPosition;

@property (nonatomic, assign) NSInteger level;

/// 元素平台
@property (nonatomic, assign) NSString *platform;

@end

NS_ASSUME_NONNULL_END
