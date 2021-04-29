//
// SAVisualizedObjectSerializerManger.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/4/23.
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
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

/// App 内嵌 H5 可视化全埋点相关信息
@interface SAVisualizedWebPageInfo : NSObject

/// H5 url
@property (nonatomic, copy) NSString *url;

/// H5 标题
@property (nonatomic, copy) NSString *title;

/// H5 可点击元素信息
@property (nonatomic, copy) NSArray *elementSources;

/// 弹框信息
@property (nonatomic, copy) NSArray <NSDictionary *>* alertSources;
@end


/// 可视化全埋点 viewTree 外层数据管理
@interface SAVisualizedObjectSerializerManger : NSObject

/// 是否包含 webview
@property (nonatomic, assign, readonly) BOOL isContainWebView;

/// 获取最后一次页面浏览所在的 controller
@property (nonatomic, strong, readonly) UIViewController *lastViewScreenController;

/// payload 新增内容对应 hash，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy, readonly) NSString *jointPayloadHash;

/// 上次截图 hash
@property (nonatomic, copy, readonly) NSString *lastImageHash;

/// 当前 App 内嵌 H5 页面信息
@property (nonatomic, strong, readonly) SAVisualizedWebPageInfo *webPageInfo;

/// 弹框信息
/* 数据结构
 [{
    "title": "弹框标题",
    "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
    "link_text": "配置文档"
    "link_url": "https://manual.sensorsdata.cn/sa/latest/app-h5-1573913.html"
 }]
 */
@property (nonatomic, strong, readonly) NSMutableArray *alertInfos;

+ (instancetype)sharedInstance;

/// 重置解析配置
- (void)resetObjectSerializer;

/// 清除 web 页面信息缓存
- (void)cleanVisualizedWebPageInfoCache;

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSDictionary *)pageInfo;

/// 读取当前 webView 页面信息
- (SAVisualizedWebPageInfo *)readWebPageInfoWithWebView:(WKWebView *)webView;

/// 进入 web 页面
- (void)enterWebViewPageWithWebInfo:(SAVisualizedWebPageInfo *)webInfo;

/// 进入页面
- (void)enterViewController:(UIViewController *)viewController;

/// 重置最后截图 hash
- (void)resetLastImageHash:(NSString *)imageHash;

/// 添加弹框
- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos;

/// 更新 payload hash
- (void)refreshPayloadHashWithData:(id)obj;

@end
