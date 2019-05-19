//  SensorsAnalyticsSDK.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import "SASecurityPolicy.h"
#import "SAConfigOptions.h"
#import "SAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class SensorsAnalyticsPeople;

/**
 * @abstract
 * 在 DEBUG 模式下，发送错误时会抛出该异常
 */
@interface SensorsAnalyticsDebugException : NSException

@end

@protocol SAUIViewAutoTrackDelegate

//UITableView
@optional
- (NSDictionary *)sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
- (NSDictionary *)sensorsAnalytics_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UIImage (SensorsAnalytics)
@property (nonatomic, copy) NSString* sensorsAnalyticsImageName;
@end

@interface UIView (SensorsAnalytics)
- (nullable UIViewController *)sensorsAnalyticsViewController;

/// viewID
@property (nonatomic, copy) NSString* sensorsAnalyticsViewID;

/// AutoTrack 时，是否忽略该 View
@property (nonatomic, assign) BOOL sensorsAnalyticsIgnoreView;

/// AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic, assign) BOOL sensorsAnalyticsAutoTrackAfterSendAction;

/// AutoTrack 时，View 的扩展属性
@property (nonatomic, strong) NSDictionary* sensorsAnalyticsViewProperties;

@property (nonatomic, weak, nullable) id sensorsAnalyticsDelegate;
@end



/**
 * @abstract
 * 自动追踪 (AutoTrack) 中，实现该 Protocal 的 Controller 对象可以通过接口向自动采集的事件中加入属性
 *
 * @discussion
 * 属性的约束请参考 track:withProperties:
 */
@protocol SAAutoTracker

@required
- (NSDictionary *)getTrackProperties;

@end

@protocol SAScreenAutoTracker<SAAutoTracker>

@required
- (NSString *)getScreenUrl;

@end

/**
 * @class
 * SensorsAnalyticsSDK 类
 *
 * @abstract
 * 在 SDK 中嵌入 SensorsAnalytics 的 SDK 并进行使用的主要 API
 *
 * @discussion
 * 使用 SensorsAnalyticsSDK 类来跟踪用户行为，并且把数据发给所指定的 SensorsAnalytics 的服务。
 * 它也提供了一个 SensorsAnalyticsPeople 类型的 property，用来访问用户 Profile 相关的 API。
 */
@interface SensorsAnalyticsSDK : NSObject

/**
 * @property
 *
 * @abstract
 * 对 SensorsAnalyticsPeople 这个 API 的访问接口
 */
@property (atomic, readonly, strong) SensorsAnalyticsPeople *people;

/**
 * @property
 *
 * @abstract
 * 获取用户的唯一用户标识
 */
@property (atomic, readonly, copy) NSString *distinctId;

/**
 * @property
 *
 * @abstract
 * 用户登录唯一标识符
 */
@property (atomic, readonly, copy) NSString *loginId;

/**
 * @proeprty
 *
 * @abstract
 * 当 App 进入后台时，是否执行 flush 将数据发送到 SensrosAnalytics
 *
 * @discussion
 * 默认值为 YES
 */
@property (atomic) BOOL flushBeforeEnterBackground;

/**
 @abstract
 用于评估是否为服务器信任的安全链接。

 @discussion
 默认使用 defaultPolicy
 */
@property (nonatomic, strong) SASecurityPolicy *securityPolicy;

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果满足这两个条件之一，则向服务器发送一次数据；如果都不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (atomic) UInt64 flushInterval __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 flushInterval")));

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量达到阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用 track、trackSignUp 以及 profileSet 等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存 10000 条数据。
 */
@property (atomic) UInt64 flushBulkSize __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 flushBulkSize")));
#pragma mark- init instance

/**
 * @abstract
 * 根据传入的配置，初始化并返回一个 SensorsAnalyticsSDK 的单例
 *
 @param configOptions 参数配置
 @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithConfig:(nonnull SAConfigOptions *)configOptions;

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用 sharedInstanceWithConfig 这个方法
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK * _Nullable)sharedInstance;

/**
 * @abstract
 * 返回预置的属性
 *
 * @return NSDictionary 返回预置的属性
 */
- (NSDictionary *)getPresetProperties;

/**
 * @abstract
 * 设置当前 serverUrl
 *
 */
- (void)setServerUrl:(NSString *)serverUrl;

#pragma mark- about webView
/**
 * @abstract
 * 将 distinctId 传递给当前的 WebView
 *
 * @discussion
 * 混合开发时,将 distinctId 传递给当前的 WebView
 *
 * @param webView 当前 WebView，支持 UIWebView 和 WKWebView
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
 * @param webView 当前 WebView，支持 UIWebView 和 WKWebView
 * @param request NSURLRequest
 * @param propertyDict NSDictionary 自定义扩展属性
 *
 * @return YES:SDK 已进行处理，NO:SDK 没有进行处理
 */
- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(nullable NSDictionary *)propertyDict;

#pragma mark--cache and flush

/**
 * @abstract
 * 设置本地缓存最多事件条数
 *
 * @discussion
 * 默认为 10000 条事件
 *
 */
@property (nonatomic, getter = getMaxCacheSize) UInt64 maxCacheSize  __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 maxCacheSize")));
- (UInt64)getMaxCacheSize __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 maxCacheSize")));

/**
 * @abstract
 * 设置 flush 时网络发送策略
 *
 * @discussion
 * 默认 3G、4G、WI-FI 环境下都会尝试 flush
 *
 * @param networkType SensorsAnalyticsNetworkType
 */
- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType;

/**
 * @abstract
 * 登录，设置当前用户的 loginId
 *
 * @param loginId 当前用户的 loginId
 */
- (void)login:(NSString *)loginId;
- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties ;

/**
 * @abstract
 * 注销，清空当前用户的 loginId
 *
 */
- (void)logout;

/**
 * @abstract
 * 获取匿名 id
 *
 * @return anonymousId 匿名 id
 */
- (NSString *)anonymousId;

/**
 * @abstract
 * 重置默认匿名 id
 */
- (void)resetAnonymousId;

/**
 * @abstract
 * 自动收集 App Crash 日志，该功能默认是关闭的
 */
- (void)trackAppCrash  __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 enableTrackAppCrash")));

/**
 * @property
 *
 * @abstract
 * 打开 SDK 自动追踪,默认只追踪App 启动 / 关闭、进入页面、元素点击
 * @discussion
 * 该功能自动追踪 App 的一些行为，例如 SDK 初始化、App 启动 / 关闭、进入页面 等等，具体信息请参考文档:
 *   https://sensorsdata.cn/manual/ios_sdk.html
 * 该功能默认关闭
 */
- (void)enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 autoTrackEventType")));

/**
 * @abstract
 * 是否开启 AutoTrack
 *
 * @return YES: 开启 AutoTrack; NO: 关闭 AutoTrack
 */
- (BOOL)isAutoTrackEnabled;

/**
 * @abstract
 * 判断某个 AutoTrack 事件类型是否被忽略
 *
 * @param eventType SensorsAnalyticsAutoTrackEventType 要判断的 AutoTrack 事件类型
 *
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType;

/**
 * @abstract
 * 忽略某一类型的 View
 *
 * @param aClass View 对应的 Class
 */
- (void)ignoreViewType:(Class)aClass;

/**
 * @abstract
 * 判断某个 View 类型是否被忽略
 *
 * @param aClass Class View 对应的 Class
 *
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isViewTypeIgnored:(Class)aClass;

/**
 * @abstract
 * 判断某个 ViewController 是否被忽略
 *
 * @param viewController UIViewController
 *
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isViewControllerIgnored:(UIViewController *)viewController;

/**
 * @abstract
 * 判断某个 ViewController 是否被忽略
 *
 * @param viewController UIViewController
 *
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isViewControllerStringIgnored:(NSString *)viewController;

/**
 * @abstract
 * 设置是否显示 debugInfoView，对于 iOS，是 UIAlertView／UIAlertController
 *
 * @discussion
 * 设置是否显示 debugInfoView，默认显示
 *
 * @param show             是否显示
 */
- (void)showDebugInfoView:(BOOL)show;

/**
 @abstract
 在初始化 SDK 之后立即调用，替换神策分析默认分配的 *匿名 ID*

 @discussion
 一般情况下，如果是一个注册用户，则应该使用注册系统内的 user_id，调用 SDK 的 login: 接口。
 对于未注册用户，则可以选择一个不会重复的匿名 ID，如设备 ID 等
 如果没有调用此方法，则使用 SDK 自动生成的匿名 ID
 SDK 会自动将设置的 anonymousId 保存到文件中，下次启动时会从中读取

 重要:该方法在 SDK 初始化之后立即调用，可以自定义匿名 ID,不要重复调用。

 @param anonymousId 当前用户的 anonymousId
 */
- (void)identify:(NSString *)anonymousId;

#pragma mark - track event
/**
 * @abstract
 * 调用 track 接口，追踪一个带有属性的 event
 *
 * @discussion
 * propertyDict 是一个 Map。
 * 其中的 key 是 Property 的名称，必须是 NSString
 * value 则是 Property 的内容，只支持 NSString、NSNumber、NSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 *
 * @param event             event的名称
 * @param propertyDict     event的属性
 */
- (void)track:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

/**
 * @abstract
 * 调用 track 接口，追踪一个无私有属性的 event
 *
 * @param event event 的名称
 */
- (void)track:(NSString *)event;

/**
 * @abstract
 * 设置 Cookie
 *
 * @param cookie NSString cookie
 * @param encode BOOL 是否 encode
 */
- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode;

/**
 * @abstract
 * 返回已设置的 Cookie
 *
 * @param decode BOOL 是否 decode
 * @return NSString cookie
 */
- (NSString *)getCookieWithDecode:(BOOL)decode;

/**
 * @abstract
 * 初始化事件的计时器。
 *
 * @discussion
 * 若需要统计某个事件的持续时间，先在事件开始时调用 trackTimer:"Event" 记录事件开始时间，该方法并不会真正发
 * 送事件；随后在事件结束时，调用 track:"Event" withProperties:properties，SDK 会追踪 "Event" 事件，并自动将事件持续时
 * 间记录在事件属性 "event_duration" 中。
 *
 * 默认时间单位为毫秒，若需要以其他时间单位统计时长，请使用 trackTimer:withTimeUnit
 *
 * 多次调用 trackTimer:"Event" 时，事件 "Event" 的开始时间以最后一次调用时为准。
 *
 * @param event             event 的名称
 */
- (void)trackTimer:(NSString *)event;

/**
 * @abstract
 * 初始化事件的计时器。
 *
 * @discussion
 * 若需要统计某个事件的持续时间，先在事件开始时调用 trackTimer:"Event" 记录事件开始时间，该方法并不会真正发
 * 送事件；随后在事件结束时，调用 track:"Event" withProperties:properties，SDK 会追踪 "Event" 事件，并自动将事件持续时
 * 间记录在事件属性 "event_duration" 中。
 *
 * 时间单位为秒，若需要以其他时间单位统计时长
 *
 * 多次调用 trackTimer:"Event" 时，事件 "Event" 的开始时间以最后一次调用时为准。
 *
 * @param event             event 的名称
 */
- (void)trackTimerStart:(NSString *)event;

/**
 * @abstract
 * 初始化事件的计时器，允许用户指定计时单位。
 *
 * @discussion
 * 请参考 trackTimer
 *
 * @param event             event 的名称
 * @param timeUnit          计时单位，毫秒/秒/分钟/小时
 */
- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit;

- (void)trackTimerEnd:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

- (void)trackTimerEnd:(NSString *)event;

- (UIViewController *_Nullable)currentViewController;

/**
 * @abstract
 * 清除所有事件计时器
 */
- (void)clearTrackTimer;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @discussion
 * propertyDict 是一个 Map。
 * 其中的 key 是 Property 的名称，必须是 NSString
 * value 则是 Property 的内容，只支持 NSString、NSNumber、NSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 *
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event 的名称
 * @param propertyDict     event 的属性
 */
- (void)trackInstallation:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @discussion
 * propertyDict 是一个 Map。
 * 其中的 key 是 Property 的名称，必须是 NSString
 * value 则是 Property 的内容，只支持 NSString、NSNumber、NSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 *
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event 的名称
 * @param propertyDict     event 的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
 */
- (void)trackInstallation:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中
 * 使用该接口
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event 的名称
 */
- (void)trackInstallation:(NSString *)event;

- (void)trackFromH5WithEvent:(NSString *)eventInfo;

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify;

/**
 * @abstract
 * 在 AutoTrack 时，用户可以设置哪些 controllers 不被 AutoTrack
 *
 * @param controllers   controller ‘字符串’数组
 */
- (void)ignoreAutoTrackViewControllers:(NSArray *)controllers;

/**
 * @abstract
 * 获取 LastScreenUrl
 *
 * @return LastScreenUrl
 */
- (NSString *)getLastScreenUrl;

/**
 * @abstract
 * App 退出或进到后台时清空 referrer，默认情况下不清空
 */
- (void)clearReferrerWhenAppEnd;

/**
 * @abstract
 * 获取 LastScreenTrackProperties
 *
 * @return LastScreenTrackProperties
 */
- (NSDictionary *)getLastScreenTrackProperties;

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

- (SensorsAnalyticsDebugMode)debugMode;

/**
 * @abstract
 * 通过代码触发 UIView 的 $AppClick 事件
 *
 * @param view UIView
 */
- (void)trackViewAppClick:(nonnull UIView *)view;

/**
 * @abstract
 * 通过代码触发 UIViewController 的 $AppViewScreen 事件
 *
 * @param viewController 当前的 UIViewController
 */
- (void)trackViewScreen:(UIViewController *)viewController;
- (void)trackViewScreen:(UIViewController *)viewController properties:(nullable NSDictionary<NSString *,id> *)properties;

/**
 * @abstract
 * 通过代码触发 UIView 的 $AppClick 事件
 *
 * @param view UIView
 * @param properties 自定义属性
 */
- (void)trackViewAppClick:(nonnull UIView *)view withProperties:(nullable NSDictionary *)properties;

/**
 @abstract
 * Track App Extension groupIdentifier 中缓存的数据
 *
 * @param groupIdentifier groupIdentifier
 * @param completion  完成 track 后的 callback
 */
- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion;

/**
 * @abstract
 * 修改入库之前的事件属性
 *
 * @param callback 传入事件名称和事件属性，可以修改或删除事件属性。请返回一个 BOOL 值，true 表示事件将入库， false 表示事件将被抛弃
 */
- (void)trackEventCallback:(BOOL (^)(NSString *eventName, NSMutableDictionary<NSString *, id> *properties))callback;

/**
 * @abstract
 * 用来设置每个事件都带有的一些公共属性
 *
 * @discussion
 * 当 track 的 Properties，superProperties 和 SDK 自动生成的 automaticProperties 有相同的 key 时，遵循如下的优先级：
 *    track.properties > superProperties > automaticProperties
 * 另外，当这个接口被多次调用时，是用新传入的数据去 merge 先前的数据，并在必要时进行 merge
 * 例如，在调用接口前，dict 是 @{@"a":1, @"b": "bbb"}，传入的 dict 是 @{@"b": 123, @"c": @"asd"}，则 merge 后的结果是
 * @{"a":1, @"b": 123, @"c": @"asd"}，同时，SDK 会自动将 superProperties 保存到文件中，下次启动时也会从中读取
 *
 * @param propertyDict 传入 merge 到公共属性的 dict
 */
- (void)registerSuperProperties:(NSDictionary *)propertyDict;

/**
 * @abstract
 * 用来设置事件的动态公共属性
 *
 * @discussion
 * 当 track 的 Properties，superProperties 和 SDK 自动生成的 automaticProperties 有相同的 key 时，遵循如下的优先级：
 *    track.properties > dynamicSuperProperties > superProperties > automaticProperties
 *
 * 例如，track.properties 是 @{@"a":1, @"b": "bbb"}，返回的 eventCommonProperty 是 @{@"b": 123, @"c": @"asd"}，
 * superProperties 是  @{@"a":1, @"b": "bbb",@"c":@"ccc"}，automaticProperties 是 @{@"a":1, @"b": "bbb",@"d":@"ddd"},
 * 则 merge 后的结果是 @{"a":1, @"b": "bbb", @"c": @"asd",@"d":@"ddd"}
 * 返回的 NSDictionary 需满足以下要求
 * 重要：1,key 必须是 NSString
 *          2,key 的名称必须符合要求
 *          3,value 的类型必须是 NSString、NSNumber、NSSet、NSArray、NSDate
 *          4,value 类型为 NSSet、NSArray 时，NSSet、NSArray 中的所有元素必须为 NSString
 * @param dynamicSuperProperties block 用来返回事件的动态公共属性
 */
- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties;

/**
 * @abstract
 * 从 superProperty 中删除某个 property
 *
 * @param property 待删除的 property 的名称
 */
- (void)unregisterSuperProperty:(NSString *)property;

/**
 * @abstract
 * 删除当前所有的 superProperty
 */
- (void)clearSuperProperties;

/**
 * @abstract
 * 拿到当前的 superProperty 的副本
 *
 * @return 当前的 superProperty 的副本
 */
- (NSDictionary *)currentSuperProperties;

/**
 * @abstract
 * 得到 SDK 的版本
 *
 * @return SDK 的版本
 */
- (NSString *)libVersion;

/**
 * @abstract
 * 强制试图把数据传到对应的 SensorsAnalytics 服务器上
 *
 * @discussion
 * 主动调用 flush 接口，则不论 flushInterval 和网络类型的限制条件是否满足，都尝试向服务器上传一次数据
 */
- (void)flush;

/**
 * @abstract
 * 删除本地缓存的全部事件
 *
 * @discussion
 * 一旦调用该接口，将会删除本地缓存的全部事件，请慎用！
 */
- (void)deleteAll;

#pragma mark Item 操作

/**
 设置 item

 @param itemType item 类型
 @param itemId item Id
 @param propertyDict item 相关属性
 */
- (void)itemSetWithType:(NSString *)itemType itemId:(NSString *)itemId properties:(nullable NSDictionary <NSString *, id> *)propertyDict;

/**
 删除 item

 @param itemType item 类型
 @param itemId item Id
 */
- (void)itemDeleteWithType:(NSString *)itemType itemId:(NSString *)itemId;


#pragma mark - VisualizedAutoTrack

/**
 * 判断是否为符合要求的 openURL
 
 * @param url 打开的 URL
 * @return YES/NO
 */
- (BOOL)canHandleURL:(NSURL *)url;

/**
 * 开启 可视化全埋点 分析，默认不开启，
 * $AppClick 事件将会采集控件的 viewPath。
 */
- (void)enableVisualizedAutoTrack;

/**
 是否开启 可视化全埋点 分析，默认不

 @return YES/NO
 */
- (BOOL)isVisualizedAutoTrackEnabled;

/**
 指定哪些页面开启 可视化全埋点 分析，
 如果指定了页面，只有这些页面的 $AppClick 事件会采集控件的 viwPath。

 @param controllers 指定的页面的类名数组
 */
- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers;

/**
 当前页面是否开启 可视化全埋点 分析。

 @param viewController 当前页面 viewController
 @return YES/NO
 */
- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController;

#pragma mark HeatMap
/**
 开启 HeatMap，$AppClick 事件将会采集控件的 viewPath
 */
- (void)enableHeatMap;

/**
 是否开启点击图

 @return YES/NO 是否开启了点击图
 */
- (BOOL)isHeatMapEnabled;

/**
 指定哪些页面开启 HeatMap，如果指定了页面
 只有这些页面的 $AppClick 事件会采集控件的 viwPath

 @param controllers 需要开启点击图的 ViewController 的类名
 */
- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers;

/**
 当前页面是否开启 点击图 分析。

 @param viewController 当前页面 viewController
 @return 当前 viewController 是否支持点击图分析
 */
- (BOOL)isHeatMapViewController:(UIViewController *)viewController;

/**
 * @abstract
 * 处理 url scheme 跳转打开 App
 *
 * @param url 打开本 app 的回调的 url
 */
- (BOOL)handleSchemeUrl:(NSURL *)url;

#pragma mark - profile
/**
 * @abstract
 * 直接设置用户的一个或者几个 Profiles
 *
 * @discussion
 * 这些 Profile 的内容用一个 NSDictionary 来存储
 * 其中的 key 是 Profile 的名称，必须是 NSString
 * Value 则是 Profile 的内容，只支持 NSString、NSNumberNSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 * 如果某个 Profile 之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profileDict 要替换的那些 Profile 的内容
 */
- (void)set:(NSDictionary *)profileDict;

/**
 * @abstract
 * 直接设置用户的pushId
 *
 * @discussion
 * 设置用户的 pushId 比如 @{@"jgId":pushId}，并触发 profileSet 设置对应的用户属性。
 * 当 disctinct_id 或者 pushId 没有发生改变的时,不会触发 profileSet。
 * @param pushKey  pushId 的 key
 * @param pushId  pushId 的值
 */
- (void)profilePushKey:(NSString *)pushKey pushId:(NSString *)pushId;

/**
 * @abstract
 * 首次设置用户的一个或者几个 Profiles
 *
 * @discussion
 * 与 set 接口不同的是，如果该用户的某个 Profile 之前已经存在了，会被忽略；不存在，则会创建
 *
 * @param profileDict 要替换的那些 Profile 的内容
 */
- (void)setOnce:(NSDictionary *)profileDict;

/**
 * @abstract
 * 设置用户的单个 Profile 的内容
 *
 * @discussion
 * 如果这个 Profile 之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profile Profile 的名称
 * @param content Profile 的内容
 */
- (void)set:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 首次设置用户的单个 Profile 的内容
 *
 * @discussion
 * 与 set 类接口不同的是，如果这个 Profile 之前已经存在了，则这次会被忽略；不存在，则会创建
 *
 * @param profile Profile 的名称
 * @param content Profile 的内容
 */
- (void)setOnce:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 删除某个 Profile 的全部内容
 *
 * @discussion
 * 如果这个 Profile 之前不存在，则直接忽略
 *
 * @param profile Profile 的名称
 */
- (void)unset:(NSString *) profile;

/**
 * @abstract
 * 给一个数值类型的 Profile 增加一个数值
 *
 * @discussion
 * 只能对 NSNumber 类型的 Profile 调用这个接口，否则会被忽略
 * 如果这个 Profile 之前不存在，则初始值当做 0 来处理
 *
 * @param profile  待增加数值的 Profile 的名称
 * @param amount   要增加的数值
 */
- (void)increment:(NSString *)profile by:(NSNumber *)amount;

/**
 * @abstract
 * 给多个数值类型的 Profile 增加数值
 *
 * @discussion
 * profileDict 中，key 是 NSString ，value 是 NSNumber
 * 其它与 - (void)increment:by: 相同
 *
 * @param profileDict 多个
 */
- (void)increment:(NSDictionary *)profileDict;

/**
 * @abstract
 * 向一个 NSSet 或者 NSArray 类型的 value 添加一些值
 *
 * @discussion
 * 如前面所述，这个 NSSet 或者 NSArray 的元素必须是 NSString，否则，会忽略
 * 同时，如果要 append 的 Profile 之前不存在，会初始化一个空的 NSSet 或者 NSArray
 *
 * @param profile profile
 * @param content description
 */
- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content;

/**
 * @abstract
 * 删除当前这个用户的所有记录
 */
- (void)deleteUser;

/**
 * @abstract
 * log 功能开关
 *
 * @discussion
 * 根据需要决定是否开启 SDK log , SensorsAnalyticsDebugOff 模式默认关闭 log
 * SensorsAnalyticsDebugOnly  SensorsAnalyticsDebugAndTrack 模式默认开启log
 *
 * @param enabelLog YES/NO
 */
- (void)enableLog:(BOOL)enabelLog;

/**
 * @abstract
 * 设备方向信息采集功能开关
 *
 * @discussion
 * 根据需要决定是否开启设备方向采集
 * 默认关闭
 *
 * @param enable YES/NO
 */
- (void)enableTrackScreenOrientation:(BOOL)enable;

/**
 * @abstract
 * 位置信息采集功能开关
 *
 * @discussion
 * 根据需要决定是否开启位置采集
 * 默认关闭
 *
 * @param enable YES/NO
 */
- (void)enableTrackGPSLocation:(BOOL)enable;

/**
 * @abstract
 * 清除 keychain 缓存数据
 *
 * @discussion
 * 注意：清除 keychain 中 kSAService 名下的数据，包括 distinct_id 和 AppInstall 标记。
 *          清除后 AppInstall 可以再次触发，造成 AppInstall 事件统计不准确。
 *
 */
- (void)clearKeychainData;

@end

/**
 * @class
 * SensorsAnalyticsPeople 类
 *
 * @abstract
 * 用于记录用户 Profile 的 API
 *
 * @discussion
 * <b>请不要自己来初始化这个类.</b> 请通过 SensorsAnalyticsSDK 提供的 people 这个 property 来调用
 */
@interface SensorsAnalyticsPeople : NSObject

/**
 * @abstract
 * 直接设置用户的一个或者几个 Profiles
 *
 * @discussion
 * 这些 Profile 的内容用一个 NSDictionary 来存储
 * 其中的 key 是 Profile 的名称，必须是 NSString
 * Value 则是 Profile 的内容，只支持 NSString、NSNumber、NSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 * 如果某个 Profile 之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profileDict 要替换的那些 Profile 的内容
 */
- (void)set:(NSDictionary *)profileDict;

/**
 * @abstract
 * 首次设置用户的一个或者几个 Profiles
 *
 * @discussion
 * 与set接口不同的是，如果该用户的某个 Profile 之前已经存在了，会被忽略；不存在，则会创建
 *
 * @param profileDict 要替换的那些 Profile 的内容
 */
- (void)setOnce:(NSDictionary *)profileDict;

/**
 * @abstract
 * 设置用户的单个 Profile 的内容
 *
 * @discussion
 * 如果这个 Profile 之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profile Profile 的名称
 * @param content Profile 的内容
 */
- (void)set:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 首次设置用户的单个 Profile 的内容
 *
 * @discussion
 * 与 set 类接口不同的是，如果这个 Profile 之前已经存在了，则这次会被忽略；不存在，则会创建
 *
 * @param profile Profile 的名称
 * @param content Profile 的内容
 */
- (void)setOnce:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 删除某个 Profile 的全部内容
 *
 * @discussion
 * 如果这个 Profile 之前不存在，则直接忽略
 *
 * @param profile Profile 的名称
 */
- (void)unset:(NSString *) profile;

/**
 * @abstract
 * 给一个数值类型的 Profile 增加一个数值
 *
 * @discussion
 * 只能对 NSNumber 类型的 Profile 调用这个接口，否则会被忽略
 * 如果这个 Profile 之前不存在，则初始值当做 0 来处理
 *
 * @param profile  待增加数值的 Profile 的名称
 * @param amount   要增加的数值
 */
- (void)increment:(NSString *)profile by:(NSNumber *)amount;

/**
 * @abstract
 * 给多个数值类型的 Profile 增加数值
 *
 * @discussion
 * profileDict 中，key是 NSString，value 是 NSNumber
 * 其它与 - (void)increment:by: 相同
 *
 * @param profileDict 多个
 */
- (void)increment:(NSDictionary *)profileDict;

/**
 * @abstract
 * 向一个 NSSet 或者 NSArray 类型的 value 添加一些值
 *
 * @discussion
 * 如前面所述，这个 NSSet 或者 NSArray 的元素必须是 NSString，否则，会忽略
 * 同时，如果要 append 的 Profile 之前不存在，会初始化一个空的 NSSet 或者 NSArray
 *
 * @param profile profile
 * @param content description
 */
- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content;

/**
 * @abstract
 * 删除当前这个用户的所有记录
 */
- (void)deleteUser;

@end

#pragma mark - Deprecated
@interface SensorsAnalyticsSDK (Deprecated)


/**
 * @abstract
 * 根据传入的配置，初始化并返回一个 SensorsAnalyticsSDK 的单例
 *
 * @param serverURL 收集事件的 URL
 * @param debugMode Sensors Analytics 的 Debug 模式
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nullable NSString *)serverURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode __attribute__((deprecated("已过时，请参考 sharedInstanceWithConfig:")));

/**
 * @abstract
 * 根据传入的配置，初始化并返回一个 SensorsAnalyticsSDK 的单例
 *
 * @param serverURL 收集事件的 URL
 * @param launchOptions launchOptions
 * @param debugMode Sensors Analytics 的 Debug 模式
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nonnull NSString *)serverURL
                                    andLaunchOptions:(NSDictionary * _Nullable)launchOptions
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode __attribute__((deprecated("已过时，请参考 sharedInstanceWithConfig:")));
/**
 * @abstract
 * 根据传入的配置，初始化并返回一个 SensorsAnalyticsSDK 的单例。
 * 目前 DebugMode 为动态开启，详细请参考说明文档：https://www.sensorsdata.cn/manual/ios_sdk.html
 * @param serverURL 收集事件的 URL
 * @param launchOptions launchOptions
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nonnull NSString *)serverURL
                                    andLaunchOptions:(NSDictionary * _Nullable)launchOptions  __attribute__((deprecated("已过时，请参考 sharedInstanceWithConfig:")));

/**
 设置调试模式
 目前 DebugMode 为动态开启，详细请参考说明文档：https://www.sensorsdata.cn/manual/ios_sdk.html
 @param debugMode 调试模式
 */
- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode __attribute__((deprecated("已过时，建议动态开启调试模式")));

/**
 * @property
 *
 * @abstract
 * 打开 SDK 自动追踪,默认只追踪App 启动 / 关闭、进入页面
 *
 * @discussion
 * 该功能自动追踪 App 的一些行为，例如 SDK 初始化、App 启动 / 关闭、进入页面 等等，具体信息请参考文档:
 *   https://sensorsdata.cn/manual/ios_sdk.html
 * 该功能默认关闭
 */
- (void)enableAutoTrack __attribute__((deprecated("已过时，请参考enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType")));

/**
 * @abstract
 * 过滤掉 AutoTrack 的某个事件类型
 *
 * @param eventType SensorsAnalyticsAutoTrackEventType 要忽略的 AutoTrack 事件类型
 */
- (void)ignoreAutoTrackEventType:(SensorsAnalyticsAutoTrackEventType)eventType __attribute__((deprecated("已过时，请参考enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType")));

/**
 * @abstract
 * 提供一个接口，用来在用户注册的时候，用注册ID来替换用户以前的匿名ID
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: http://www.sensorsdata.cn/manual/track_signup.html，并在必要时联系我们的技术支持人员。
 *
 * @param newDistinctId     用户完成注册后生成的注册ID
 * @param propertyDict     event的属性
 */
- (void)trackSignUp:(NSString *)newDistinctId withProperties:(nullable NSDictionary *)propertyDict __attribute__((deprecated("已过时，请参考login")));

/**
 * @abstract
 * 不带私有属性的trackSignUp，用来在用户注册的时候，用注册ID来替换用户以前的匿名ID
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: http://www.sensorsdata.cn/manual/track_signup.html，并在必要时联系我们的技术支持人员。
 *
 * @param newDistinctId     用户完成注册后生成的注册ID
 */
- (void)trackSignUp:(NSString *)newDistinctId __attribute__((deprecated("已过时，请参考login")));

/**
 * @abstract
 * 初始化事件的计时器。
 *
 * @discussion
 * 若需要统计某个事件的持续时间，先在事件开始时调用 trackTimer:"Event" 记录事件开始时间，该方法并不会真正发
 * 送事件；随后在事件结束时，调用 track:"Event" withProperties:properties，SDK 会追踪 "Event" 事件，并自动将事件持续时
 * 间记录在事件属性 "event_duration" 中。
 *
 * 默认时间单位为毫秒，若需要以其他时间单位统计时长，请使用 trackTimer:withTimeUnit
 *
 * 多次调用 trackTimer:"Event" 时，事件 "Event" 的开始时间以最后一次调用时为准。
 *
 * @param event             event的名称
 */
- (void)trackTimerBegin:(NSString *)event __attribute__((deprecated("已过时，请参考 trackTimerStart")));

/**
 * @abstract
 * 初始化事件的计时器，允许用户指定计时单位。
 *
 * @discussion
 * 请参考 trackTimer
 *
 * @param event             event的名称
 * @param timeUnit          计时单位，毫秒/秒/分钟/小时
 */
- (void)trackTimerBegin:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit __attribute__((deprecated("已过时，请参考 trackTimerStart")));


#pragma mark- heatMap
/**
 * @abstract
 * 神策 SDK 会处理 点击图，可视化全埋点url
 * @discussion
 *  目前处理 heatmap，visualized
 * @param url 点击图的 url
 * @return YES/NO
 */
- (BOOL)handleHeatMapUrl:(NSURL *)url __attribute__((deprecated("已过时，请参考 handleSchemeUrl:")));

/**
 * @abstract
 * Track $AppViewScreen事件
 *
 * @param url 当前页面url
 * @param properties 用户扩展属性
 */
- (void)trackViewScreen:(NSString *)url withProperties:(NSDictionary *)properties __attribute__((deprecated("已过时，请参考 trackViewScreen: properties:")));
@end

NS_ASSUME_NONNULL_END

