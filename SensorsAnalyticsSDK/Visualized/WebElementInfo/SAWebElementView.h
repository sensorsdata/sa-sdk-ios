//
// SAWebElementView.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/2/20.
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

#import "SAVisualizedElementView.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// H5 页面元素构造
@interface SAWebElementView : SAVisualizedElementView

/// 根据 web 页面元素信息构造对象
- (instancetype)initWithWebView:(WKWebView *)webView webElementInfo:(NSDictionary *)elementInfo;

// html 标签名称
@property (nonatomic, copy) NSString *tagName;

/// 元素选择器，H5 元素不支持限定位置时匹配
@property (nonatomic, copy) NSString *elementSelector;

/// 元素是否可见
@property (nonatomic, assign, getter=isVisible) BOOL visible;

/// 元素所在页面 url
@property (nonatomic, copy) NSString *url;

/// 元素在列表内的相对位置，列表元素才会有
@property (nonatomic, copy) NSString *listSelector;

/// Web JS SDK 版本号
@property (nonatomic, copy) NSString *libVersion;

@end

NS_ASSUME_NONNULL_END
