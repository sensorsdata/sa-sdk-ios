//  SensorsAnalyticsSDK.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright (c) 2015年 SensorsData. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

NS_ASSUME_NONNULL_BEGIN

@class SensorsAnalyticsPeople;

/**
 * @abstract
 * 在DEBUG模式下，发送错误时会抛出该异常
 */
@interface SensorsAnalyticsDebugException : NSException

@end

@protocol SAUIViewAutoTrackDelegate

//UITableView
@optional
-(NSDictionary *) sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
-(NSDictionary *) sensorsAnalytics_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//@optional
//-(NSDictionary *) sensorsAnalytics_alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
//
//@optional
//-(NSDictionary *) sensorsAnalytics_actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface UIImage (SensorsAnalytics)
@property (nonatomic,copy) NSString* sensorsAnalyticsImageName;
@end

@interface UIView (SensorsAnalytics)
- (nullable UIViewController *)viewController;

//viewID
@property (copy,nonatomic) NSString* sensorsAnalyticsViewID;

//AutoTrack 时，是否忽略该 View
@property (nonatomic,assign) BOOL sensorsAnalyticsIgnoreView;

//AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic,assign) BOOL sensorsAnalyticsAutoTrackAfterSendAction;

//AutoTrack 时，View 的扩展属性
@property (strong,nonatomic) NSDictionary* sensorsAnalyticsViewProperties;

@property (nonatomic, weak, nullable) id sensorsAnalyticsDelegate;
@end

/**
 * @abstract
 * Debug模式，用于检验数据导入是否正确。该模式下，事件会逐条实时发送到SensorsAnalytics，并根据返回值检查
 * 数据导入是否正确。
 *
 * @discussion
 * Debug模式的具体使用方式，请参考:
 *  http://www.sensorsdata.cn/manual/debug_mode.html
 *
 * Debug模式有三种选项:
 *   SensorsAnalyticsDebugOff - 关闭DEBUG模式
 *   SensorsAnalyticsDebugOnly - 打开DEBUG模式，但该模式下发送的数据仅用于调试，不进行数据导入
 *   SensorsAnalyticsDebugAndTrack - 打开DEBUG模式，并将数据导入到SensorsAnalytics中
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsDebugMode) {
    SensorsAnalyticsDebugOff,
    SensorsAnalyticsDebugOnly,
    SensorsAnalyticsDebugAndTrack,
};

/**
 * @abstract
 * TrackTimer 接口的时间单位。调用该接口时，传入时间单位，可以设置 event_duration 属性的时间单位。
 *
 * @discuss
 * 时间单位有以下选项：
 *   SensorsAnalyticsTimeUnitMilliseconds - 毫秒
 *   SensorsAnalyticsTimeUnitSeconds - 秒
 *   SensorsAnalyticsTimeUnitMinutes - 分钟
 *   SensorsAnalyticsTimeUnitHours - 小时
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsTimeUnit) {
    SensorsAnalyticsTimeUnitMilliseconds,
    SensorsAnalyticsTimeUnitSeconds,
    SensorsAnalyticsTimeUnitMinutes,
    SensorsAnalyticsTimeUnitHours
};


/**
 * @abstract
 * AutoTrack 中的事件类型
 *
 * @discussion
 *   SensorsAnalyticsEventTypeAppStart - $AppStart
 *   SensorsAnalyticsEventTypeAppEnd - $AppEnd
 *   SensorsAnalyticsEventTypeAppClick - $AppClick
 *   SensorsAnalyticsEventTypeAppViewScreen - $AppViewScreen
 */
typedef NS_OPTIONS(NSInteger, SensorsAnalyticsAutoTrackEventType) {
    SensorsAnalyticsEventTypeNone      = 0,
    SensorsAnalyticsEventTypeAppStart      = 1 << 0,
    SensorsAnalyticsEventTypeAppEnd        = 1 << 1,
    SensorsAnalyticsEventTypeAppClick      = 1 << 2,
    SensorsAnalyticsEventTypeAppViewScreen = 1 << 3,
};

/**
 * @abstract
 * 网络类型
 *
 * @discussion
 *   SensorsAnalyticsNetworkTypeNONE - NULL
 *   SensorsAnalyticsNetworkType2G - 2G
 *   SensorsAnalyticsNetworkType3G - 3G
 *   SensorsAnalyticsNetworkType4G - 4G
 *   SensorsAnalyticsNetworkTypeWIFI - WIFI
 *   SensorsAnalyticsNetworkTypeALL - ALL
 */
typedef NS_OPTIONS(NSInteger, SensorsAnalyticsNetworkType) {
    SensorsAnalyticsNetworkTypeNONE      = 0,
    SensorsAnalyticsNetworkType2G       = 1 << 0,
    SensorsAnalyticsNetworkType3G       = 1 << 1,
    SensorsAnalyticsNetworkType4G       = 1 << 2,
    SensorsAnalyticsNetworkTypeWIFI     = 1 << 3,
    SensorsAnalyticsNetworkTypeALL      = 0xFF,
};

/**
 * @abstract
 * 自动追踪(AutoTrack)中，实现该 Protocal 的 Controller 对象可以通过接口向自动采集的事件中加入属性
 *
 * @discussion
 * 属性的约束请参考 <code>track:withProperties:</code>
 */
@protocol SAAutoTracker

@required
-(NSDictionary *)getTrackProperties;

@end

@protocol SAScreenAutoTracker<SAAutoTracker>

@required
-(NSString *) getScreenUrl;

@end

/**
 * @class
 * SensorsAnalyticsSDK类
 *
 * @abstract
 * 在SDK中嵌入SensorsAnalytics的SDK并进行使用的主要API
 *
 * @discussion
 * 使用SensorsAnalyticsSDK类来跟踪用户行为，并且把数据发给所指定的SensorsAnalytics的服务。
 * 它也提供了一个<code>SensorsAnalyticsPeople</code>类型的property，用来访问用户Profile相关的API。
 */
@interface SensorsAnalyticsSDK : NSObject

/**
 * @property
 *
 * @abstract
 * 对<code>SensorsAnalyticsPeople</code>这个API的访问接口
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
 * @property
 *
 * @abstract
 * 当App进入活跃状态时，是否从SensrosAnalytics获取新的可视化埋点配置
 *
 * @discussion
 * 默认值为 YES。
 */
@property (atomic) BOOL checkForEventBindingsOnActive;

/**
 * @proeprty
 *
 * @abstract
 * 当App进入后台时，是否执行flush将数据发送到SensrosAnalytics
 *
 * @discussion
 * 默认值为 YES
 */
@property (atomic) BOOL flushBeforeEnterBackground;

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用track、trackSignUp以及profileSet等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否WIFI/3G/4G网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (atomic) UInt64 flushInterval;

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量达到阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用track、trackSignUp以及profileSet等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否WIFI/3G/4G网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否达到 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (atomic) UInt64 flushBulkSize;

/**
 * @property
 *
 * @abstract
 * 可视化埋点中，UIWindow 对象。
 *
 * @discussion
 * 该方法应在 SDK 初始化完成后立即调用
 *
 * 默认值为App 的 UIWindow 对象是 UIApplication 的 windows 列表中的 firstObject，若用户调用 UIWindow 的 makeKeyAndVisible 等方法，
 * 改变了 windows 列表中各个对象的 windowLevel，会导致可视化埋点无法正常获取需要埋点的 UIWindow 对象。用户调用该借口，设置可视化埋点需要管理的
 * UIWindow 对象
 */
@property (atomic) UIWindow *vtrackWindow;

#pragma mark- init instance
/**
 * @abstract
 * 根据传入的配置，初始化并返回一个<code>SensorsAnalyticsSDK</code>的单例
 *
 * @discussion
 * 该方法会根据 <code>configureURL</code> 参数的 Url Path，自动计算可视化埋点配置系统的 Url。例如，若传入的 <code>configureURL</code> 为:
 *     http://sa_host:8007/api/vtrack/config/iOS.conf
 * 则会自动生成可视化埋点配置系统的 Url:
 *     ws://sa_host:8007/api/ws
 * 若用户私有环境中部署了 Sensors Analytics 系统，并修改了 Nginx 配置，则需要使用 SensorsAnalyticsSDK#sharedInstanceWithServerURL:andConfigureURL:andDebugMode 进行初始化。
 *
 * @param serverURL 收集事件的 URL
 * @param configureURL 获取配置信息的 URL
 * @param debugMode Sensors Analytics 的 Debug 模式
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nullable NSString *)serverURL
                                     andConfigureURL:(nullable NSString *)configureURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode;

/**
 * @abstract
 * 根据传入的配置，初始化并返回一个<code>SensorsAnalyticsSDK</code>的单例
 *
 * @param serverURL 收集事件的URL
 * @param configureURL 获取配置信息的URL
 * @param vtrackServerURL 可视化埋点配置系统的URL
 * @param debugMode Sensors Analytics 的Debug模式
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nullable NSString *)serverURL
                                     andConfigureURL:(nullable NSString *)configureURL
                                  andVTrackServerURL:(nullable NSString *)vtrackServerURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode;

/**
 * @abstract
 * 根据传入的配置，初始化并返回一个<code>SensorsAnalyticsSDK</code>的单例
 *
 * @param serverURL 收集事件的URL
 * @param debugMode Sensors Analytics 的Debug模式
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nullable NSString *)serverURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode;

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用<code>sharedInstanceWithServerURL</code>这个方法
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sharedInstance;

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

/**
 * @abstract
 * 允许 App 连接可视化埋点管理界面
 *
 * @discussion
 * 调用这个方法，允许 App 连接可视化埋点管理界面并设置可视化埋点。建议用户只在 DEBUG 编译模式下，打开该选项。
 *
 */
- (void)enableEditingVTrack;

#pragma mark- about webView
/**
 * @abstract
 * 将distinctId传递给当前的WebView
 *
 * @discussion
 * 混合开发时,将distinctId传递给当前的WebView
 *
 * @param webView 当前WebView，支持<code>UIWebView</code>和<code>WKWebView</code>
 *
 * @return YES:SDK已进行处理，NO:SDK没有进行处理
 */
- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request;

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify;

/**
 * @abstract
 * 将distinctId传递给当前的WebView
 *
 * @discussion
 * 混合开发时,将distinctId传递给当前的WebView
 *
 * @param webView 当前WebView，支持<code>UIWebView</code>和<code>WKWebView</code>
 * @param request NSURLRequest
 * @param propertyDict NSDictionary 自定义扩展属性
 *
 * @return YES:SDK已进行处理，NO:SDK没有进行处理
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
 * @param maxCacheSize 本地缓存最多事件条数
 */
- (void)setMaxCacheSize:(UInt64)maxCacheSize;

- (UInt64)getMaxCacheSize;

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
 * 登录，设置当前用户的loginId
 *
 * @param loginId 当前用户的loginId
 */
- (void)login:(NSString *)loginId;

/**
 * @abstract
 * 注销，清空当前用户的loginId
 *
 */
- (void)logout;

/**
 * @abstract
 * 获取匿名id
 *
 * @return anonymousId 匿名id
 */
- (NSString *)anonymousId;

/**
 * @abstract
 * 重置默认匿名id
 */
- (void)resetAnonymousId;

/**
 * @abstract
 * 自动收集 App Crash 日志，该功能默认是关闭的
 */
- (void)trackAppCrash;

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
 * @property
 *
 * @abstract
 * 打开 SDK 自动追踪,默认只追踪App 启动 / 关闭、进入页面、元素点击
 *
 * @discussion
 * 该功能自动追踪 App 的一些行为，例如 SDK 初始化、App 启动 / 关闭、进入页面 等等，具体信息请参考文档:
 *   https://sensorsdata.cn/manual/ios_sdk.html
 * 该功能默认关闭
 */
- (void)enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType;

/**
 * @abstract
 * 是否开启 AutoTrack
 *
 * @return YES:开启 AutoTrack; NO:关闭 AutoTrack
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
- (BOOL)isViewControllerIgnored:(UIViewController*)viewController;

/**
 * @abstract
 * 判断某个 ViewController 是否被忽略
 *
 * @param viewController UIViewController
 *
 * @return YES:被忽略; NO:没有被忽略
 */
- (BOOL)isViewControllerStringIgnored:(NSString*)viewController;

/**
 * @abstract
 * 过滤掉 AutoTrack 的某个事件类型
 *
 * @param eventType SensorsAnalyticsAutoTrackEventType 要忽略的 AutoTrack 事件类型
 */
- (void)ignoreAutoTrackEventType:(SensorsAnalyticsAutoTrackEventType)eventType __attribute__((deprecated("已过时，请参考enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType")));

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

- (NSString *)getUIViewControllerTitle:(UIViewController *)controller;

/**
 * @abstract
 * 设置当前用户的distinctId
 *
 * @discussion
 * 一般情况下，如果是一个注册用户，则应该使用注册系统内的user_id
 * 如果是个未注册用户，则可以选择一个不会重复的匿名ID，如设备ID等
 * 如果客户没有设置indentify，则使用SDK自动生成的匿名ID
 * SDK会自动将设置的distinctId保存到文件中，下次启动时会从中读取
 *
 * @param distinctId 当前用户的distinctId
 */
- (void)identify:(NSString *)distinctId;
#pragma mark - track event
/**
 * @abstract
 * 调用track接口，追踪一个带有属性的event
 *
 * @discussion
 * propertyDict是一个Map。
 * 其中的key是Property的名称，必须是<code>NSString</code>
 * value则是Property的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,<code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 *
 * @param event             event的名称
 * @param propertyDict     event的属性
 */
- (void)track:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

/**
 * @abstract
 * 调用track接口，追踪一个无私有属性的event
 *
 * @param event event的名称
 */
- (void)track:(NSString *)event;

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
 * 默认时间单位为毫秒，若需要以其他时间单位统计时长，请使用 trackTimer:withTimeUnit
 *
 * 多次调用 trackTimer:"Event" 时，事件 "Event" 的开始时间以最后一次调用时为准。
 *
 * @param event             event的名称
 */
- (void)trackTimerBegin:(NSString *)event;

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
- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit;

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
- (void)trackTimerBegin:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit;

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
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @discussion
 * propertyDict是一个Map。
 * 其中的key是Property的名称，必须是<code>NSString</code>
 * value则是Property的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,<code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 *
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event的名称
 * @param propertyDict     event的属性
 */
- (void)trackInstallation:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @discussion
 * propertyDict是一个Map。
 * 其中的key是Property的名称，必须是<code>NSString</code>
 * value则是Property的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,<code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 *
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event的名称
 * @param propertyDict     event的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
 */
- (void)trackInstallation:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，SDK会将渠道值填入事件属性 $utm_ 开头的一系列属性中
 * 使用该接口
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: https://sensorsdata.cn/manual/track_installation.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event的名称
 */
- (void)trackInstallation:(NSString *)event;

- (void)trackFromH5WithEvent:(NSString *)eventInfo;

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify;

/**
 * @abstract
 * 在AutoTrack时，用户可以设置哪些controlls不被AutoTrack
 *
 * @param controllers   controller‘字符串’数组
 */
- (void)ignoreAutoTrackViewControllers:(NSArray *)controllers;

/**
 * @abstract
 * 获取LastScreenUrl
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

/**
 * @abstract
 * 通过代码触发 UIView 的 $AppClick 事件
 *
 * @param view UIView
 * @param properties 自定义属性
 */
- (void)trackViewAppClick:(nonnull UIView *)view withProperties:(nullable NSDictionary *)properties;

/**
 * @abstract
 * Track $AppViewScreen事件
 *
 * @param url 当前页面url
 * @param properties 用户扩展属性
 */
- (void)trackViewScreen:(NSString *)url withProperties:(NSDictionary *)properties;

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
 * 用来设置每个事件都带有的一些公共属性
 *
 * @discussion
 * 当track的Properties，superProperties和SDK自动生成的automaticProperties有相同的key时，遵循如下的优先级：
 *    track.properties > superProperties > automaticProperties
 * 另外，当这个接口被多次调用时，是用新传入的数据去merge先前的数据，并在必要时进行merger
 * 例如，在调用接口前，dict是@{@"a":1, @"b": "bbb"}，传入的dict是@{@"b": 123, @"c": @"asd"}，则merge后的结果是
 * @{"a":1, @"b": 123, @"c": @"asd"}，同时，SDK会自动将superProperties保存到文件中，下次启动时也会从中读取
 *
 * @param propertyDict 传入merge到公共属性的dict
 */
- (void)registerSuperProperties:(NSDictionary *)propertyDict;

/**
 * @abstract
 * 从superProperty中删除某个property
 *
 * @param property 待删除的property的名称
 */
- (void)unregisterSuperProperty:(NSString *)property;

/**
 * @abstract
 * 删除当前所有的superProperty
 */
- (void)clearSuperProperties;

/**
 * @abstract
 * 拿到当前的superProperty的副本
 *
 * @return 当前的superProperty的副本
 */
- (NSDictionary *)currentSuperProperties;

/**
 * @abstract
 * 得到SDK的版本
 *
 * @return SDK的版本
 */
- (NSString *)libVersion;

/**
 * @abstract
 * 强制试图把数据传到对应的SensorsAnalytics服务器上
 *
 * @discussion
 * 主动调用flush接口，则不论flushInterval和网络类型的限制条件是否满足，都尝试向服务器上传一次数据
 */
- (void)flush;
#pragma mark- heatMap
- (BOOL)handleHeatMapUrl:(NSURL *)url;

/**
 * @abstract
 * 开启 HeatMap，$AppClick 事件将会采集控件的 viewPath
 */
- (void)enableHeatMap;

- (BOOL)isHeatMapEnabled;

/**
 * @abstract
 * 指定哪些页面开启 HeatMap，如果指定了页面，只有这些页面的 $AppClick 事件会采集控件的 viwPath
 */
- (void)addHeatMapViewControllers:(NSArray *)controllers;

- (BOOL)isHeatMapViewController:(UIViewController *)viewController;
#pragma mark- profile
/**
 * @abstract
 * 直接设置用户的一个或者几个Profiles
 *
 * @discussion
 * 这些Profile的内容用一个<code>NSDictionary</code>来存储
 * 其中的key是Profile的名称，必须是<code>NSString</code>
 * Value则是Profile的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,
 *                              <code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 * 如果某个Profile之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profileDict 要替换的那些Profile的内容
 */
- (void)set:(NSDictionary *)profileDict;

/**
 * @abstract
 * 首次设置用户的一个或者几个Profiles
 *
 * @discussion
 * 与set接口不同的是，如果该用户的某个Profile之前已经存在了，会被忽略；不存在，则会创建
 *
 * @param profileDict 要替换的那些Profile的内容
 */
- (void)setOnce:(NSDictionary *)profileDict;

/**
 * @abstract
 * 设置用户的单个Profile的内容
 *
 * @discussion
 * 如果这个Profile之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profile Profile的名称
 * @param content Profile的内容
 */
- (void)set:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 首次设置用户的单个Profile的内容
 *
 * @discussion
 * 与set类接口不同的是，如果这个Profile之前已经存在了，则这次会被忽略；不存在，则会创建
 *
 * @param profile Profile的名称
 * @param content Profile的内容
 */
- (void)setOnce:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 删除某个Profile的全部内容
 *
 * @discussion
 * 如果这个Profile之前不存在，则直接忽略
 *
 * @param profile Profile的名称
 */
- (void)unset:(NSString *) profile;

/**
 * @abstract
 * 给一个数值类型的Profile增加一个数值
 *
 * @discussion
 * 只能对<code>NSNumber</code>类型的Profile调用这个接口，否则会被忽略
 * 如果这个Profile之前不存在，则初始值当做0来处理
 *
 * @param profile  待增加数值的Profile的名称
 * @param amount   要增加的数值
 */
- (void)increment:(NSString *)profile by:(NSNumber *)amount;

/**
 * @abstract
 * 给多个数值类型的Profile增加数值
 *
 * @discussion
 * profileDict中，key是<code>NSString</code>，value是<code>NSNumber</code>
 * 其它与-(void)increment:by:相同
 *
 * @param profileDict 多个
 */
- (void)increment:(NSDictionary *)profileDict;

/**
 * @abstract
 * 向一个<code>NSSet</code>类型的value添加一些值
 *
 * @discussion
 * 如前面所述，这个<code>NSSet</code>的元素必须是<code>NSString</code>，否则，会忽略
 * 同时，如果要append的Profile之前不存在，会初始化一个空的<code>NSSet</code>
 *
 * @param profile profile
 * @param content description
 */
- (void)append:(NSString *)profile by:(NSSet *)content;

/**
 * @abstract
 * 删除当前这个用户的所有记录
 */
- (void)deleteUser;

/**
 * @abstract
 * log功能开关
 *
 * @discussion
 * 根据需要决定是否开启 SDK log , SensorsAnalyticsDebugOff 模式默认关闭 log
 * SensorsAnalyticsDebugOnly  SensorsAnalyticsDebugAndTrack 模式默认开启log
 *
 * @param enabelLog YES/NO
 */
- (void)enableLog:(BOOL)enabelLog;
@end

/**
 * @class
 * SensorsAnalyticsPeople类
 *
 * @abstract
 * 用于记录用户Profile的API
 *
 * @discussion
 * <b>请不要自己来初始化这个类.</b> 请通过<code>SensorsAnalyticsSDK</code>提供的<code>people</code>这个property来调用
 */
@interface SensorsAnalyticsPeople : NSObject

/**
 * @abstract
 * 完成<code>SensorsAnalyticsPeople</code>的初始化
 *
 * @discussion
 * 一般情况下，请不要直接初始化<code>SensorsAnalyticsPeople</code>，而是通过<code>SensorsAnalyticsSDK</code>的property来调用
 *
 * @param sdk 传入的<code>SensorsAnalyticsSDK</code>对象
 *
 * @return 初始化后的结果
 */
- (id)initWithSDK:(SensorsAnalyticsSDK *)sdk;

/**
 * @abstract
 * 直接设置用户的一个或者几个Profiles
 *
 * @discussion
 * 这些Profile的内容用一个<code>NSDictionary</code>来存储
 * 其中的key是Profile的名称，必须是<code>NSString</code>
 * Value则是Profile的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,
 *                              <code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 * 如果某个Profile之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profileDict 要替换的那些Profile的内容
 */
- (void)set:(NSDictionary *)profileDict;

/**
 * @abstract
 * 首次设置用户的一个或者几个Profiles
 *
 * @discussion
 * 与set接口不同的是，如果该用户的某个Profile之前已经存在了，会被忽略；不存在，则会创建
 *
 * @param profileDict 要替换的那些Profile的内容
 */
- (void)setOnce:(NSDictionary *)profileDict;

/**
 * @abstract
 * 设置用户的单个Profile的内容
 *
 * @discussion
 * 如果这个Profile之前已经存在了，则这次会被覆盖掉；不存在，则会创建
 *
 * @param profile Profile的名称
 * @param content Profile的内容
 */
- (void)set:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 首次设置用户的单个Profile的内容
 *
 * @discussion
 * 与set类接口不同的是，如果这个Profile之前已经存在了，则这次会被忽略；不存在，则会创建
 *
 * @param profile Profile的名称
 * @param content Profile的内容
 */
- (void)setOnce:(NSString *) profile to:(id)content;

/**
 * @abstract
 * 删除某个Profile的全部内容
 *
 * @discussion
 * 如果这个Profile之前不存在，则直接忽略
 *
 * @param profile Profile的名称
 */
- (void)unset:(NSString *) profile;

/**
 * @abstract
 * 给一个数值类型的Profile增加一个数值
 *
 * @discussion
 * 只能对<code>NSNumber</code>类型的Profile调用这个接口，否则会被忽略
 * 如果这个Profile之前不存在，则初始值当做0来处理
 *
 * @param profile  待增加数值的Profile的名称
 * @param amount   要增加的数值
 */
- (void)increment:(NSString *)profile by:(NSNumber *)amount;

/**
 * @abstract
 * 给多个数值类型的Profile增加数值
 *
 * @discussion
 * profileDict中，key是<code>NSString</code>，value是<code>NSNumber</code>
 * 其它与-(void)increment:by:相同
 *
 * @param profileDict 多个
 */
- (void)increment:(NSDictionary *)profileDict;

/**
 * @abstract
 * 向一个<code>NSSet</code>类型的value添加一些值
 *
 * @discussion
 * 如前面所述，这个<code>NSSet</code>的元素必须是<code>NSString</code>，否则，会忽略
 * 同时，如果要append的Profile之前不存在，会初始化一个空的<code>NSSet</code>
 *
 * @param profile profile
 * @param content description
 */
- (void)append:(NSString *)profile by:(NSSet *)content;

/**
 * @abstract
 * 删除当前这个用户的所有记录
 */
- (void)deleteUser;

@end

NS_ASSUME_NONNULL_END
