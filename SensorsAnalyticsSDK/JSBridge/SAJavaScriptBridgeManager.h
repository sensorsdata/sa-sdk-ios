//
// SAJavaScriptBridgeManager.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/3/18.
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
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAJavaScriptBridgeManager : NSObject <WKScriptMessageHandler, SAModuleProtocol, SAJavaScriptBridgeModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;

@end


/**
 * @abstract
 * App 调用 JS 方法的类型。
 *
 * @discussion
 * 调用 JS 方法类型枚举
 */
typedef NS_ENUM(NSInteger, SAJavaScriptCallJSType) {
    /// 进入可视化扫码模式通知 JS
    SAJavaScriptCallJSTypeVisualized,
    /// 检测是否集成 JS SDK
    SAJavaScriptCallJSTypeCheckJSSDK,
    /// 更新自定义属性配置
    SAJavaScriptCallJSTypeUpdateVisualConfig,
    /// 获取 App 内嵌 H5 采集的自定义属性
    SAJavaScriptCallJSTypeWebVisualProperties
};

/// 打通写入 serverURL
extern NSString * const kSAJSBridgeServerURL;

/// 可视化通知已进入扫码模式
extern NSString * const kSAJSBridgeVisualizedMode;

/// js 方法调用
extern NSString * const kSAJSBridgeCallMethod;

/// 构建 js 相关 bridge 和变量
@interface SAJavaScriptBridgeBuilder : NSObject

#pragma mark 注入 js
/// 注入打通bridge，并设置 serverURL
/// @param serverURL 数据接收地址
+ (nullable NSString *)buildJSBridgeWithServerURL:(NSString *)serverURL;

/// 注入可视化 bridge，并设置扫码模式
/// @param isVisualizedMode 是否为可视化扫码模式
+ (nullable NSString *)buildVisualBridgeWithVisualizedMode:(BOOL)isVisualizedMode;

/// 注入自定义属性 bridge，配置信息
/// @param originalConfig 配置信息原始 json
+ (nullable NSString *)buildVisualPropertyBridgeWithVisualConfig:(NSDictionary *)originalConfig;

#pragma mark JS 调用

/// js 方法调用
/// @param type 调用类型
/// @param object 传参
+ (nullable NSString *)buildCallJSMethodStringWithType:(SAJavaScriptCallJSType)type jsonObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
