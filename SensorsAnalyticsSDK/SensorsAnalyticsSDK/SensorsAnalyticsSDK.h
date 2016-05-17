//  SensorsAnalyticsSDK.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright (c) 2015年 SensorsData. All rights reserved.

#import <Foundation/Foundation.h>

@class SensorsAnalyticsPeople;

/**
 * @abstract
 * 在DEBUG模式下，发送错误时会抛出该异常
 */
@interface SensorsAnalyticsDebugException : NSException

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
 *   SensorsAnalyticsDebugModeOff - 关闭DEBUG模式
 *   DebugOnly - 打开DEBUG模式，但该模式下发送的数据仅用于调试，不进行数据导入
 *   DebugAndTrack - 打开DEBUG模式，并将数据导入到SensorsAnalytics中
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsDebugMode) {
    SensorsAnalyticsDebugOff,
    SensorsAnalyticsDebugOnly,
    SensorsAnalyticsDebugAndTrack,
};

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
 * 默认值为 60 * 1000 毫秒， 在每次调用track、trackSignUp以及profileSet等接口的时候，
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
 * 可视化埋点中，UIWindow 对象的序号
 *
 * @discussion
 * 默认值为 0。一般情况下，App 的 UIWindow 对象是 UIApplication 的 windows 列表中的 firstObject，若用户调用 UIWindow 的 makeKeyAndVisible 等方法，
 * 改变了 windows 列表中各个对象的 windowLevel，会导致可视化埋点无法正常获取需要埋点的 UIWindow 对象。用户调用该借口，设置 UIWindow 对象在
 * windows 列表中的 index。
 */
@property (atomic) UInt32 vtrackWindowIndex;

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
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                     andConfigureURL:(NSString *)configureURL
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
+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                     andConfigureURL:(NSString *)configureURL
                                  andVTrackServerURL:(NSString *)vtrackServerURL
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
 * @param propertieDict     event的属性
 */
- (void)track:(NSString *)event withProperties:(NSDictionary *)propertyDict;

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
 * 多次调用 trackTimer:"Event" 时，事件 "Event" 的开始时间以最后一次调用时为准。
 *
 * @param event             event的名称
 */
- (void)trackTimer:(NSString *)event;

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
 * @param propertieDict     event的属性
 */
- (void)signUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertyDict __deprecated;

- (void)trackSignUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertyDict;

/**
 * @abstract
 * 不带私有属性的trackSignUp，用来在用户注册的时候，用注册ID来替换用户以前的匿名ID
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: http://www.sensorsdata.cn/manual/track_signup.html，并在必要时联系我们的技术支持人员。
 *
 * @param newDistinctId     用户完成注册后生成的注册ID
 */
- (void)signUp:(NSString *)newDistinctId __deprecated;

- (void)trackSignUp:(NSString *)newDistinctId;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK会将渠道值填入事件属性 $ios_install_source 中
 *
 * @discussion
 * propertyDict是一个Map。
 * 其中的key是Property的名称，必须是<code>NSString</code>
 * value则是Property的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,<code>NSDate</code>这些类型
 * 特别的，<code>NSSet</code>类型的value中目前只支持其中的元素是<code>NSString</code>
 * 
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: http://www.sensorsdata.cn/manual/ios_sdk.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event的名称
 * @param propertieDict     event的属性
 */
- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，SDK会将渠道值填入事件属性 $ios_install_source 中
 *
 * @discussion
 * 这个接口是一个较为复杂的功能，请在使用前先阅读相关说明: http://www.sensorsdata.cn/manual/ios_sdk.html，并在必要时联系我们的技术支持人员。
 *
 * @param event             event的名称
 */
- (void)trackInstallation:(NSString *)event;

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

/**
 * @abstract
 * 当前有多少条记录在缓存中
 *
 * @discussion
 * 这个函数并不是线程安全的，取值的同时可能被其它线程修改
 *
 * @return 当前的记录条数
 */
- (NSUInteger) currentQueueCount;

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
 * Valie则是Profile的内容，只支持 <code>NSString</code>,<code>NSNumber</code>,<code>NSSet</code>,
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
 * @param profile
 * @param content <#content description#>
 */
- (void)append:(NSString *)profile by:(NSSet *)content;

/**
 * @abstract
 * 删除当前这个用户的所有记录
 */
- (void)deleteUser;

@end
