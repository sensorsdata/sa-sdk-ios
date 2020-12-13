//
// SensorsAnalyticsSDK+WKWebView.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/4.
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
#import "SensorsAnalyticsSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (WKWebView)

/**
 * @abstract
 * H5 数据打通的时候默认通过 ServerUrl 校验
 */
- (void)addWebViewUserAgentSensorsDataFlag;

/**
 * @abstract
 * H5 数据打通的时候是否通过 ServerUrl 校验, 如果校验通过，H5 的事件数据走 App 上报否则走 JSSDK 上报
 *
 * @param enableVerify YES/NO   校验通过后可走 App，上报数据/直接走 App，上报数据
 */
- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify;

/**
 * @abstract
 * H5 数据打通的时候是否通过 ServerUrl 校验, 如果校验通过，H5 的事件数据走 App 上报否则走 JSSDK 上报
 *
 * @param enableVerify YES/NO   校验通过后可走 App，上报数据/直接走 App，上报数据
 * @param userAgent  userAgent = nil ,SDK 会从 webview 中读取 ua

 */
- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify userAgent:(nullable NSString *)userAgent;
/**
 * @abstract
 * 将 distinctId 传递给当前的 WebView
 *
 * @discussion
 * 混合开发时,将 distinctId 传递给当前的 WebView
 *
 * @param webView 当前 WebView，支持 WKWebView
 *
 * @return YES:SDK 已进行处理，NO:SDK 没有进行处理
 */
- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request;

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify;

/**
 * @abstract
 * 将 distinctId 传递给当前的 WebView
 *
 * @discussion
 * 混合开发时,将 distinctId 传递给当前的 WebView
 *
 * @param webView 当前 WebView，支持 WKWebView
 * @param request NSURLRequest
 * @param propertyDict NSDictionary 自定义扩展属性
 *
 * @return YES:SDK 已进行处理，NO:SDK 没有进行处理
 */
- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(nullable NSDictionary *)propertyDict;

@end

NS_ASSUME_NONNULL_END
