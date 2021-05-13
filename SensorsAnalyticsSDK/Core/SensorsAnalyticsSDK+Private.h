//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SANetwork.h"
#import "SAHTTPSession.h"
#import "SATrackEventObject.h"

@interface SensorsAnalyticsSDK(Private)

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用 startWithConfigOptions: 。
 * 这个方法与 sharedInstance 类似，但是当远程配置关闭 SDK 时，sharedInstance 方法会返回 nil，这个方法仍然能获取到 SDK 的单例
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sdkInstance;

#pragma mark - method
- (void)autoTrackViewScreen:(UIViewController *)viewController;

/// 事件采集: 切换到 serialQueue 中执行
/// @param object 事件对象
/// @param properties 事件属性
- (void)asyncTrackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties;

/**
 根据 viewController 判断，是否采集事件

 @param controller 事件采集时的控制器
 @param type 事件类型
 @return 是否采集
 */
- (BOOL)shouldTrackViewController:(UIViewController *)controller ofType:(SensorsAnalyticsAutoTrackEventType)type;

/**
向 WKWebView 注入 Message Handler

@param webView 需要注入的 wkwebView
*/
- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;

/// 开启可视化模块
- (void)enableVisualize;

#pragma mark - property
@property (nonatomic, strong, readonly) SAConfigOptions *configOptions;
@property (nonatomic, readonly, class) SAConfigOptions *configOptions;

@property (nonatomic, strong, readonly) SANetwork *network;

@property (nonatomic, weak) UIViewController *previousTrackViewController;

@end



/**
 SAConfigOptions 实现
 私有 property
 */
@interface SAConfigOptions()

/// 数据接收地址 serverURL
@property(atomic, copy) NSString *serverURL;

/// App 启动的 launchOptions
@property(nonatomic, strong) id launchOptions;

@end

#endif /* SensorsAnalyticsSDK_priv_h */
