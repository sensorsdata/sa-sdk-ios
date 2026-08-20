//
// SensorsAnalyticsSDK+Public.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAConstants.h"
#import "SAPropertyPlugin.h"

@class SASecurityPolicy;
@class SAConfigOptions;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const SensorsAnalyticsIdentityKeyIDFA;
extern NSString * const SensorsAnalyticsIdentityKeyMobile;
extern NSString * const SensorsAnalyticsIdentityKeyEmail;

/**
 * @class
 * SensorsAnalyticsSDK 类
 *
 * @abstract
 * 在 SDK 中嵌入 SensorsAnalytics 的 SDK 并进行使用的主要 API
 *
 * @discussion
 * 使用 SensorsAnalyticsSDK 类来跟踪用户行为，并且把数据发给所指定的 SensorsAnalytics 的服务。
 */
@interface SensorsAnalyticsSDK : NSObject

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
@property (atomic, readonly, copy, nullable) NSString *loginId;

#pragma mark- init instance
/**
 通过配置参数，配置神策 SDK

 此方法调用必须符合以下条件：
     1、必须在应用启动时调用，即在 application:didFinishLaunchingWithOptions: 中调用，
     2、必须在主线线程中调用
     3、必须在 SDK 其他方法调用之前调用
 如果不符合上述条件，存在丢失 $AppStart 事件及应用首页的 $AppViewScreen 事件风险

 @param configOptions 参数配置
 */
+ (void)startWithConfigOptions:(nonnull SAConfigOptions *)configOptions NS_SWIFT_NAME(start(configOptions:));

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用 startWithConfigOptions: 这个方法
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK * _Nullable)sharedInstance;

/// 禁用 SDK。调用后，SDK 将不采集事件，不发送网络请求
+ (void)disableSDK;

/// 开启 SDK。如果之前 SDK 是禁止状态，调用后将恢复数据采集功能
+ (void)enableSDK;

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
 * @discussion
 * 默认不请求远程配置
 *
 * @param serverUrl 当前的 serverUrl
 *
 */
- (void)setServerUrl:(NSString *)serverUrl;

/**
 * @abstract
 * 获取当前 serverUrl
 */
- (NSString *)serverUrl;

/**
* @abstract
* 设置当前 serverUrl，并选择是否请求远程配置
*
* @param serverUrl 当前的 serverUrl
* @param isRequestRemoteConfig 是否请求远程配置
*/
- (void)setServerUrl:(NSString *)serverUrl isRequestRemoteConfig:(BOOL)isRequestRemoteConfig API_UNAVAILABLE(macos, tvos, watchos) NS_EXTENSION_UNAVAILABLE("RemoteConfig not supported for iOS extensions.");

#pragma mark--cache and flush

/**
 * @abstract
 * 登录，设置当前用户的 loginId
 *
 * @param loginId 当前用户的 loginId
 */
- (void)login:(NSString *)loginId;

/**
 登录，设置当前用户的 loginId

 触发 $SignUp 事件。
 ⚠️属性为事件属性，非用户属性

 @param loginId 当前用户的登录 id
 @param properties $SignUp 事件的事件属性
 */
- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties;

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

#pragma mark - 业务 ID

/**
 @abstract
 ID-Mapping 3.0 功能下已绑定的业务 ID 列表
 */
- (NSDictionary *)identities;

/**
 @abstract
 ID-Mapping 3.0 功能下绑定业务 ID 功能

 @param key 绑定业务 ID 的键名
 @param value 绑定业务 ID 的键值
 */
- (void)bind:(NSString *)key value:(NSString *)value;

/**
 @abstract
 ID-Mapping 3.0 功能下解绑业务 ID 功能

 @param key 解绑业务 ID 的键名
 @param value 解绑业务 ID 的键值
 */
- (void)unbind:(NSString *)key value:(NSString *)value;

/// ID3 reset anonymous identity
- (void)resetAnonymousIdentity:(nullable NSString *)identity;
#pragma mark - trackTimer
/**
 开始事件计时

 @discussion
 若需要统计某个事件的持续时间，先在事件开始时调用 trackTimerStart:"Event" 记录事件开始时间，该方法并不会真正发送事件；
 随后在事件结束时，调用 trackTimerEnd:"Event" withProperties:properties，
 SDK 会追踪 "Event" 事件，并自动将事件持续时间记录在事件属性 "event_duration" 中，时间单位为秒。

 @param event 事件名称
 @return 返回计时事件的 eventId，用于交叉计时场景。普通计时可忽略
 */
- (nullable NSString *)trackTimerStart:(NSString *)event;

/**
 结束事件计时

 @discussion
 多次调用 trackTimerEnd: 时，以首次调用为准

 @param event 事件名称或事件的 eventId
 @param propertyDict 自定义属性
 */
- (void)trackTimerEnd:(NSString *)event withProperties:(nullable NSDictionary *)propertyDict;

/**
 结束事件计时

 @discussion
 多次调用 trackTimerEnd: 时，以首次调用为准

 @param event 事件名称或事件的 eventId
 */
- (void)trackTimerEnd:(NSString *)event;

/**
 暂停事件计时

 @discussion
 多次调用 trackTimerPause: 时，以首次调用为准。

 @param event 事件名称或事件的 eventId
 */
- (void)trackTimerPause:(NSString *)event;

/**
 恢复事件计时

 @discussion
 多次调用 trackTimerResume: 时，以首次调用为准。

 @param event 事件名称或事件的 eventId
 */
- (void)trackTimerResume:(NSString *)event;

/**
删除事件计时

 @discussion
 多次调用 removeTimer: 时，只有首次调用有效。

 @param event 事件名称或事件的 eventId
*/
- (void)removeTimer:(NSString *)event;

/**
 清除所有事件计时器
 */
- (void)clearTrackTimer;

#pragma mark track event
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
 * 修改入库之前的事件属性
 *
 * @param callback 传入事件名称和事件属性，可以修改或删除事件属性。请返回一个 BOOL 值，true 表示事件将入库， false 表示事件将被抛弃
 */
- (void)trackEventCallback:(BOOL (^)(NSString *eventName, NSMutableDictionary<NSString *, id> *properties))callback __attribute__((deprecated("已过时，请使用 SAConfigOptions 类的 trackEventCallback")));

- (void)registerLimitKeys:(NSDictionary<SALimitKey, NSString *> *)keys;

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
 * 注册属性插件
 *
 * @param plugin 属性插件对象
 */
- (void)registerPropertyPlugin:(SAPropertyPlugin *)plugin;

/**
 * @abstract
 * 注销属性插件
 *
 * @param pluginClass 插件类型
 */
- (void)unregisterPropertyPluginWithPluginClass:(Class)pluginClass;

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
 * 主动调用 flush 接口，则不论 flushInterval 和 flushBulkSize 限制条件是否满足，都尝试向服务器上传一次数据
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

/**
 * 判断是否为符合要求的 openURL

 * @param url 打开的 URL
 * @return YES/NO
 */
- (BOOL)canHandleURL:(NSURL *)url API_UNAVAILABLE(macos, tvos, watchos) NS_EXTENSION_UNAVAILABLE("HandleURL not supported for iOS extensions.");

/**
 * @abstract
 * 处理 url scheme 跳转打开 App
 *
 * @param url 打开本 app 的回调的 url
 */
- (BOOL)handleSchemeUrl:(NSURL *)url API_UNAVAILABLE(macos, tvos, watchos) NS_EXTENSION_UNAVAILABLE("HandleURL not supported for iOS extensions.");

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
 * @param pushTypeKey  pushId 的 key
 * @param pushId  pushId 的值
 */
- (void)profilePushKey:(NSString *)pushTypeKey pushId:(NSString *)pushId;

/**
 * @abstract
 * 删除用户设置的 pushId
 *
 * *@discussion
 * 删除用户设置的 pushId 比如 @{@"jgId":pushId}，并触发 profileUnset 删除对应的用户属性。
 * 当 disctinct_id 未找到本地缓存记录时, 不会触发 profileUnset。
 * @param pushTypeKey  pushId 的 key
 */
- (void)profileUnsetPushKey:(NSString *)pushTypeKey;

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
 * 清除 keychain 缓存数据
 *
 * @discussion
 * 注意：清除 keychain 中 kSAService 名下的数据，包括 distinct_id 标记。
 *
 */
- (void)clearKeychainData API_UNAVAILABLE(macos) NS_EXTENSION_UNAVAILABLE("KeychainData not supported for iOS extensions.");

/// 设置单次发送事件的最大条数
- (void)setBatchSize:(NSInteger)batchSize;

@end

#pragma mark - Deprecated
@interface SensorsAnalyticsSDK (Deprecated)

/**
 * @property
 *
 * @abstract
 * 两次数据发送的最小时间间隔，单位毫秒
 *
 * @discussion
 * 默认值为 15 * 1000 毫秒， 在每次调用 track 和 profileSet 等接口的时候，
 * 都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否超过 flushBulkSize
 * 如果满足这两个条件之一，则向服务器发送一次数据；如果都不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存10000条数据。
 */
@property (atomic) NSInteger flushInterval __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 flushInterval")));

/**
 * @property
 *
 * @abstract
 * 本地缓存的最大事件数目，当累积日志量超过阈值时发送数据
 *
 * @discussion
 * 默认值为 100，在每次调用 track 和 profileSet 等接口的时候，都会检查如下条件，以判断是否向服务器上传数据:
 * 1. 是否 WIFI/3G/4G 网络
 * 2. 是否满足以下数据发送条件之一:
 *   1) 与上次发送的时间间隔是否大于 flushInterval
 *   2) 本地缓存日志数目是否超过 flushBulkSize
 * 如果同时满足这两个条件，则向服务器发送一次数据；如果不满足，则把数据加入到队列中，等待下次检查时把整个队列的内容一并发送。
 * 需要注意的是，为了避免占用过多存储，队列最多只缓存 10000 条数据。
 */
@property (atomic) NSInteger flushBulkSize __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 flushBulkSize")));

/**
 * @abstract
 * 设置本地缓存最多事件条数
 *
 * @discussion
 * 默认为 10000 条事件
 *
 */
@property (nonatomic) NSInteger maxCacheSize  __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 maxCacheSize")));

/**
 * @abstract
 * 设置 flush 时网络发送策略
 *
 * @discussion
 * 默认 3G、4G、WI-FI 环境下都会尝试 flush
 *
 * @param networkType SensorsAnalyticsNetworkType
 */
- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType  __attribute__((deprecated("已过时，请参考 SAConfigOptions 类的 flushNetworkPolicy")));

/**
 设置调试模式
 目前 DebugMode 为动态开启，详细请参考说明文档：https://www.sensorsdata.cn/manual/ios_sdk.html
 @param debugMode 调试模式
 */
- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode __attribute__((deprecated("已过时，建议动态开启调试模式"))) NS_EXTENSION_UNAVAILABLE("DebugMode not supported for iOS extensions.");

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
- (void)trackTimer:(NSString *)event __attribute__((deprecated("已过时，请参考 trackTimerStart")));

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
- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit __attribute__((deprecated("已过时，请参考 trackTimerStart")));

/**
 ⚠️ 此接口为 ID-Mapping 3.0 解决值域冲突的特殊场景下的接口，请咨询确认后再使用!!

 @param key 当前用户的登录 ID key
 @param loginId 当前用户的登录 ID
 */
- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId __attribute__((deprecated("已过期，旧版本如使用此接口请继续，新用户请不要使用此方法！")));

@end

NS_ASSUME_NONNULL_END
