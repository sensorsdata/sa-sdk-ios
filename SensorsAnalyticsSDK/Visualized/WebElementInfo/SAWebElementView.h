//
// SAWebElementView.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/2/20.
// Copyright © 2020 SensorsData. All rights reserved.
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
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// H5 页面元素构造
@interface SAWebElementView : UIView

/// 根据 web 页面元素信息构造对象
- (instancetype)initWithWebView:(WKWebView *)webView webElementInfo:(NSDictionary *)elementInfo;

// html 标签名称
@property (nonatomic, copy) NSString *tagName;
/// 是否为 H5 元素
@property (nonatomic, assign) BOOL isFromH5;

/// 元素选择器，老版使用
@property (nonatomic, copy) NSString *elementSelector;

/// 元素内容
@property (nonatomic, copy) NSString *elementContent;

/// 元素是否可见
@property (nonatomic, assign) BOOL visibility;

/// 元素所在页面 url
@property (nonatomic, copy) NSString *url;

/// H5 页面标题
@property (nonatomic, copy) NSString *title;

/// js 生成的 H5 元素 id
@property (nonatomic, copy) NSString *jsElementId;

/// js 解析的 H5 子元素 id
@property (nonatomic, copy) NSArray<NSString *> *jsSubElementIds;

/// js 解析的 H5 子元素
@property (nonatomic, copy) NSArray<SAWebElementView *> *jsSubviews;

/// 是否可点击
@property (nonatomic, assign) BOOL enableAppClick;

/// 是否为列表
@property (nonatomic, assign) BOOL isListView;

/// 元素路径，新版使用
@property (nonatomic, copy) NSString *elementPath;

/// 元素位置
@property (nonatomic, copy) NSString *elementPosition;

/// 元素在列表内的相对位置，列表元素才会有
@property (nonatomic, copy) NSString *listSelector;

/// Web JS SDK 版本号
@property (nonatomic, copy) NSString *webLibVersion;

@property (nonatomic, assign) NSInteger level;
@end

NS_ASSUME_NONNULL_END
