//
// SensorsAnalyticsSDK.m
// SensorsAnalyticsSDK
//
// Created by 曹犟 on 15/7/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK.h"
#import "SAKeyChainItemWrapper.h"
#import "SACommonUtility.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SATrackTimer.h"
#import "SAReachability.h"
#import "SAIdentifier.h"
#import "SAValidator.h"
#import "SALog+Private.h"
#import "SAConsoleLogger.h"
#import "SAModuleManager.h"
#import "SAAppLifecycle.h"
#import "SAReferrerManager.h"
#import "SAProfileEventObject.h"
#import "SAItemEventObject.h"
#import "SAJSONUtil.h"
#import "SAPropertyPluginManager.h"
#import "SAPresetPropertyPlugin.h"
#import "SAAppVersionPropertyPlugin.h"
#import "SADeviceIDPropertyPlugin.h"
#import "SAApplication.h"
#import "SAEventTrackerPluginManager.h"
#import "SAStoreManager.h"
#import "SAFileStorePlugin.h"
#import "SAUserDefaultsStorePlugin.h"
#import "SASessionProperty.h"
#import "SAFlowManager.h"
#import "SANetworkInfoPropertyPlugin.h"
#import "SACarrierNamePropertyPlugin.h"
#import "SAEventObjectFactory.h"
#import "SASuperPropertyPlugin.h"
#import "SADynamicSuperPropertyPlugin.h"
#import "SAReferrerTitlePropertyPlugin.h"
#import "SAEventDurationPropertyPlugin.h"
#import "SAFirstDayPropertyPlugin.h"
#import "SAModulePropertyPlugin.h"
#import "SASessionPropertyPlugin.h"
#import "SAEventStore.h"
#import "SALimitKeyManager.h"
#import "NSDictionary+SACopyProperties.h"

#define VERSION @"4.4.8"

void *SensorsAnalyticsQueueTag = &SensorsAnalyticsQueueTag;

static dispatch_once_t sdkInitializeOnceToken;
static SensorsAnalyticsSDK *sharedInstance = nil;
NSString * const SensorsAnalyticsIdentityKeyIDFA = @"$identity_idfa";
NSString * const SensorsAnalyticsIdentityKeyMobile = @"$identity_mobile";
NSString * const SensorsAnalyticsIdentityKeyEmail = @"$identity_email";

@interface SensorsAnalyticsSDK()

@property (nonatomic, strong) SANetwork *network;

@property (nonatomic, strong) SAEventStore *eventStore;

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@property (nonatomic, strong) SATrackTimer *trackTimer;

@property (nonatomic, strong) NSTimer *timer;

// 兼容 UA 值打通逻辑，后续废弃 UA 值打通逻辑时可以全部移除
@property (atomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *addWebViewUserAgent;

@property (nonatomic, strong) SAConfigOptions *configOptions;

@property (nonatomic, copy) BOOL (^trackEventCallback)(NSString *, NSMutableDictionary<NSString *, id> *);

@property (nonatomic, strong) SAIdentifier *identifier;

@property (nonatomic, strong) SASessionProperty *sessionProperty;

@property (atomic, strong) SAConsoleLogger *consoleLogger;

@property (nonatomic, strong) SAAppLifecycle *appLifecycle;

@end

@implementation SensorsAnalyticsSDK

#pragma mark - Initialization
+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions {
    NSAssert(sensorsdata_is_same_queue(dispatch_get_main_queue()), @"The iOS SDK must be initialized in the main thread, otherwise it will cause unexpected problems (such as missing $AppStart event).");
    
    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[SensorsAnalyticsSDK alloc] initWithConfigOptions:configOptions];
        [SAModuleManager startWithConfigOptions:sharedInstance.configOptions];
        [sharedInstance addAppLifecycleObservers];
    });
}

+ (SensorsAnalyticsSDK *_Nullable)sharedInstance {
    if ([SAModuleManager.sharedInstance isDisableSDK]) {
        SALogDebug(@"SDK is disabled");
        return nil;
    }
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sdkInstance {
    return sharedInstance;
}

+ (void)disableSDK {
    SensorsAnalyticsSDK *instance = SensorsAnalyticsSDK.sdkInstance;
    if (instance.configOptions.disableSDK) {
        return;
    }
    [instance track:@"$AppDataTrackingClose"];
    [instance flush];

    [instance clearTrackTimer];
    [instance stopFlushTimer];
    [instance removeObservers];
    [instance removeWebViewUserAgent];

    [SAReachability.sharedInstance stopMonitoring];

    [SAModuleManager.sharedInstance disableAllModules];

    instance.configOptions.disableSDK = YES;

    //disable all event tracker plugins
    [[SAEventTrackerPluginManager defaultManager] disableAllPlugins];

    SALogWarn(@"SensorsAnalyticsSDK disabled");
    [SALog sharedLog].enableLog = NO;
}

+ (void)enableSDK {
    SensorsAnalyticsSDK *instance = SensorsAnalyticsSDK.sdkInstance;
    if (!instance.configOptions.disableSDK) {
        return;
    }
    instance.configOptions.disableSDK = NO;
    // 部分模块和监听依赖网络状态，所以需要优先开启
    [SAReachability.sharedInstance startMonitoring];

    // 优先添加远程控制监听，防止热启动时关闭 SDK 的情况下
    [instance addRemoteConfigObservers];

    if (instance.configOptions.enableLog) {
        [instance enableLog:YES];
    }
    
    [SAModuleManager startWithConfigOptions:instance.configOptions];

    // 需要在模块加载完成之后添加监听，如果过早会导致退到后台后，$AppEnd 事件无法立即上报
    [instance addAppLifecycleObservers];

    [instance appendWebViewUserAgent];
    [instance startFlushTimer];

    //enable all event tracker plugins
    [[SAEventTrackerPluginManager defaultManager] enableAllPlugins];

    SALogInfo(@"SensorsAnalyticsSDK enabled");
}

- (instancetype)initWithConfigOptions:(nonnull SAConfigOptions *)configOptions {
    @try {
        self = [super init];
        if (self) {
            _configOptions = [configOptions copy];

            // 优先开启 log, 防止部分日志输出不生效(比如: SAIdentifier 初始化时校验 loginIDKey)
            if (!_configOptions.disableSDK && _configOptions.enableLog) {
                [self enableLog:_configOptions.enableLog];
            }

            [self resgisterStorePlugins];

            _appLifecycle = [[SAAppLifecycle alloc] init];

            NSString *serialQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.serialQueue.%p", self];
            _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_serialQueue, SensorsAnalyticsQueueTag, &SensorsAnalyticsQueueTag, NULL);

            NSString *readWriteQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.readWriteQueue.%p", self];
            _readWriteQueue = dispatch_queue_create([readWriteQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);

            _network = [[SANetwork alloc] init];

            NSString *path = [SAFileStorePlugin filePath:kSADatabaseDefaultFileName];
            _eventStore = [SAEventStore eventStoreWithFilePath:path];

            _trackTimer = [[SATrackTimer alloc] init];

            _identifier = [[SAIdentifier alloc] initWithQueue:_readWriteQueue];

            if (_configOptions.enableSession) {
                _sessionProperty = [[SASessionProperty alloc] initWithMaxInterval:_configOptions.eventSessionTimeout * 1000];
            } else {
                [SASessionProperty removeSessionModel];
            }

            // 初始化注册内部插件
            [self registerPropertyPlugin];

            if (!_configOptions.disableSDK) {
                [[SAReachability sharedInstance] startMonitoring];
                [self addRemoteConfigObservers];
            }

        #if TARGET_OS_IOS
            [self setupSecurityPolicyWithConfigOptions:_configOptions];

            [SAReferrerManager sharedInstance].serialQueue = _serialQueue;
        #endif
            //start flush timer for App Extension
            if ([SAApplication isAppExtension]) {
                [self startFlushTimer];
            }

            [SAFlowManager sharedInstance].configOptions = self.configOptions;

            [SAFlowManager.sharedInstance loadFlows];
        }
        
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resgisterStorePlugins {
    SAFileStorePlugin *filePlugin = [[SAFileStorePlugin alloc] init];
    [[SAStoreManager sharedInstance] registerStorePlugin:filePlugin];

    SAUserDefaultsStorePlugin *userDefaultsPlugin = [[SAUserDefaultsStorePlugin alloc] init];
    [[SAStoreManager sharedInstance] registerStorePlugin:userDefaultsPlugin];

    for (id<SAStorePlugin> plugin in self.configOptions.storePlugins) {
        [[SAStoreManager sharedInstance] registerStorePlugin:plugin];
    }
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerPropertyPlugin {
    SANetworkInfoPropertyPlugin *networkInfoPlugin = [[SANetworkInfoPropertyPlugin alloc] init];
    SACarrierNamePropertyPlugin *carrierPlugin = [[SACarrierNamePropertyPlugin alloc] init];

    dispatch_async(self.serialQueue, ^{
        // 注册 configOptions 中自定义属性插件
        for (SAPropertyPlugin * plugin in self.configOptions.propertyPlugins) {
            [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:plugin];
        }
        
        // 预置属性
        SAPresetPropertyPlugin *presetPlugin = [[SAPresetPropertyPlugin alloc] initWithLibVersion:VERSION];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:presetPlugin];

        // 应用版本
        SAAppVersionPropertyPlugin *appVersionPlugin = [[SAAppVersionPropertyPlugin alloc] init];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:appVersionPlugin];

        // deviceID，super 优先级，不能被覆盖
        SADeviceIDPropertyPlugin *deviceIDPlugin = [[SADeviceIDPropertyPlugin alloc] init];
        deviceIDPlugin.disableDeviceId = self.configOptions.disableDeviceId;
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:deviceIDPlugin];

        // 运营商信息
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:carrierPlugin];

        // 注册静态公共属性插件
        SASuperPropertyPlugin *superPropertyPlugin = [[SASuperPropertyPlugin alloc] init];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:superPropertyPlugin];

        // 动态公共属性
        SADynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [SADynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:dynamicSuperPropertyPlugin];

        // 网络相关信息
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:networkInfoPlugin];

        // 事件时长，根据 event 计算，不支持 H5
        SAEventDurationPropertyPlugin *eventDurationPropertyPlugin = [[SAEventDurationPropertyPlugin alloc] initWithTrackTimer:self.trackTimer];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:eventDurationPropertyPlugin];

        // ReferrerTitle
        SAReferrerTitlePropertyPlugin *referrerTitlePropertyPlugin = [[SAReferrerTitlePropertyPlugin alloc] init];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:referrerTitlePropertyPlugin];

        // IsFirstDay
        SAFirstDayPropertyPlugin *firstDayPropertyPlugin = [[SAFirstDayPropertyPlugin alloc] initWithQueue:self.readWriteQueue];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:firstDayPropertyPlugin];

        // SAModuleManager.sharedInstance.properties
        SAModulePropertyPlugin *modulePropertyPlugin = [[SAModulePropertyPlugin alloc] init];
        [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:modulePropertyPlugin];

        // sessionProperty
        if (self.sessionProperty) {
            SASessionPropertyPlugin *sessionPropertyPlugin = [[SASessionPropertyPlugin alloc] initWithSessionProperty:self.sessionProperty];
            [[SAPropertyPluginManager sharedInstance] registerPropertyPlugin:sessionPropertyPlugin];
        }
    });
}

#if TARGET_OS_IOS
- (void)setupSecurityPolicyWithConfigOptions:(SAConfigOptions *)options {
    SASecurityPolicy *securityPolicy = options.securityPolicy;
    if (!securityPolicy) {
        return;
    }
    
#ifdef DEBUG
    NSURL *serverURL = [NSURL URLWithString:options.serverURL];
    if (securityPolicy.SSLPinningMode != SASSLPinningModeNone && ![serverURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case SASSLPinningModeNone:
                pinningMode = @"SASSLPinningModeNone";
                break;
            case SASSLPinningModeCertificate:
                pinningMode = @"SASSLPinningModeCertificate";
                break;
            case SASSLPinningModePublicKey:
                pinningMode = @"SASSLPinningModePublicKey";
                break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
#endif
    
    SAHTTPSession.sharedInstance.securityPolicy = securityPolicy;
}
#endif

- (void)enableLoggers {
    if (!self.consoleLogger) {
        SAConsoleLogger *consoleLogger = [[SAConsoleLogger alloc] init];
        [SALog addLogger:consoleLogger];
        self.consoleLogger = consoleLogger;
    }
}

+ (UInt64)getCurrentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (UInt64)getSystemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (NSDictionary *)getPresetProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    void(^block)(void) = ^{
        NSDictionary *dic = [[SAPropertyPluginManager sharedInstance] currentPropertiesForPluginClasses:@[SAPresetPropertyPlugin.class, SADeviceIDPropertyPlugin.class, SACarrierNamePropertyPlugin.class, SANetworkInfoPropertyPlugin.class, SAFirstDayPropertyPlugin.class, SAAppVersionPropertyPlugin.class]];
        [properties addEntriesFromDictionary:dic];
    };
    if (sensorsdata_is_same_queue(self.serialQueue)) {
        block();
    } else {
        dispatch_sync(self.serialQueue, block);
    }
    return properties;
}

- (void)setServerUrl:(NSString *)serverUrl {
#if TARGET_OS_OSX
    if (serverUrl && ![serverUrl isKindOfClass:[NSString class]]) {
        SALogError(@"%@ serverUrl must be NSString, please check the value!", self);
        return;
    }
    // macOS 暂不支持远程控制，即不支持 setServerUrl: isRequestRemoteConfig: 接口
    dispatch_async(self.serialQueue, ^{
        self.configOptions.serverURL = serverUrl;
    });
#else
    [self setServerUrl:serverUrl isRequestRemoteConfig:NO];
#endif
}

- (NSString *)serverUrl {
    return self.configOptions.serverURL;
}

- (void)setServerUrl:(NSString *)serverUrl isRequestRemoteConfig:(BOOL)isRequestRemoteConfig {
    if (serverUrl && ![serverUrl isKindOfClass:[NSString class]]) {
        SALogError(@"%@ serverUrl must be NSString, please check the value!", self);
        return;
    }

    dispatch_async(self.serialQueue, ^{
        if (![self.configOptions.serverURL isEqualToString:serverUrl]) {
            self.configOptions.serverURL = serverUrl;

            // 更新数据接收地址
            [SAModuleManager.sharedInstance updateServerURL:serverUrl];
        }

        if (isRequestRemoteConfig) {
            [SAModuleManager.sharedInstance retryRequestRemoteConfigWithForceUpdateFlag:YES];
        }
    });
}

- (void)login:(NSString *)loginId {
    [self login:loginId withProperties:nil];
}

- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties {
    [self loginWithKey:kSAIdentitiesLoginId loginId:loginId properties:properties];
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId {
    [self loginWithKey:key loginId:loginId properties:nil];
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId properties:(NSDictionary * _Nullable )properties {
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];

    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForLogin:key value:loginId]) {
            return;
        }
        [self.identifier loginWithKey:key loginId:loginId];
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGIN_NOTIFICATION object:nil];
        [self trackEventObject:object properties:properties];
    });
}

- (void)logout {
    dispatch_async(self.serialQueue, ^{
        BOOL isLogin = (self.loginId.length > 0);
        // logout 中会将 self.loginId 清除，因此需要在 logout 之前获取当前登录状态
        [self.identifier logout];
        if (isLogin) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGOUT_NOTIFICATION object:nil];
        }
    });
}

- (NSString *)loginId {
    return self.identifier.loginId;
}

- (NSString *)anonymousId {
    return self.identifier.anonymousId;
}

- (NSString *)distinctId {
    return self.identifier.distinctId;
}

- (void)resetAnonymousId {
    dispatch_async(self.serialQueue, ^{
        NSString *previousAnonymousId = [self.anonymousId copy];
        [self.identifier resetAnonymousId];
        if (self.loginId || [previousAnonymousId isEqualToString:self.anonymousId]) {
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_RESETANONYMOUSID_NOTIFICATION object:nil];
    });
}

- (void)flush {
    [self flushAllEventRecords];
}

- (void)deleteAll {
    dispatch_async(self.serialQueue, ^{
        [self.eventStore deleteAllRecords];
    });
}


#pragma mark - AppLifecycle

/// 在所有模块加载完成之后调用，添加通知
/// 注意⚠️：不要随意调整通知添加顺序
- (void)addAppLifecycleObservers {
    if (self.configOptions.disableSDK) {
        return;
    }
    // app extension does not need state observer
    if ([SAApplication isAppExtension]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kSAAppLifecycleStateWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
}

// 处理事件触发之前的逻辑
- (void)appLifecycleStateWillChange:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    SAAppLifecycleState oldState = [userInfo[kSAAppLifecycleOldStateKey] integerValue];

    // 热启动
    if (oldState != SAAppLifecycleStateInit && newState == SAAppLifecycleStateStart) {
        // 遍历 trackTimer
        UInt64 currentSysUpTime = [self.class getSystemUpTime];
        dispatch_async(self.serialQueue, ^{
            [self.trackTimer resumeAllEventTimers:currentSysUpTime];
        });
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        // 清除本次启动解析的来源渠道信息
        [SAModuleManager.sharedInstance clearUtmProperties];
        // 停止计时器
        [self stopFlushTimer];
        // 遍历 trackTimer
        UInt64 currentSysUpTime = [self.class getSystemUpTime];
        dispatch_async(self.serialQueue, ^{
            [self.trackTimer pauseAllEventTimers:currentSysUpTime];
        });
        // 清除 $referrer
        [[SAReferrerManager sharedInstance] clearReferrer];
    }
}

// 处理事件触发之后的逻辑
- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];

    // 冷（热）启动
    if (newState == SAAppLifecycleStateStart) {
        // 开启定时器
        [self startFlushTimer];
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {

#if TARGET_OS_IOS
        UIApplication *application = [SAApplication sharedApplication];
        __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        void (^endBackgroundTask)(void) = ^() {
            [application endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        };
        backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:endBackgroundTask];

        dispatch_async(self.serialQueue, ^{
            [self flushAllEventRecordsWithCompletion:^{
                // 结束后台任务
                endBackgroundTask();
            }];
        });
#else
        dispatch_async(self.serialQueue, ^{
            // 上传所有的数据
            [self flushAllEventRecords];
        });
#endif

        return;
    }

    // 终止
    if (newState == SAAppLifecycleStateTerminate) {
        dispatch_sync(self.serialQueue, ^{});
    }
}

#pragma mark - HandleURL
- (BOOL)canHandleURL:(NSURL *)url {
    return [SAModuleManager.sharedInstance canHandleURL:url];
}

- (BOOL)handleSchemeUrl:(NSURL *)url {
    if (!url) {
        return NO;
    }
    
    // 退到后台时的网络状态变化不会监听，因此通过 handleSchemeUrl 唤醒 App 时主动获取网络状态
    [[SAReachability sharedInstance] startMonitoring];

    return [SAModuleManager.sharedInstance handleURL:url];
}

#pragma mark - Item 操作

- (void)itemSetWithType:(NSString *)itemType itemId:(NSString *)itemId properties:(nullable NSDictionary <NSString *, id> *)propertyDict {
    SAItemEventObject *object = [[SAItemEventObject alloc] initWithType:kSAEventItemSet itemType:itemType itemID:itemId];
    dispatch_async(self.serialQueue, ^{
        [self trackEventObject:object properties:propertyDict];
    });
}

- (void)itemDeleteWithType:(NSString *)itemType itemId:(NSString *)itemId {
    SAItemEventObject *object = [[SAItemEventObject alloc] initWithType:kSAEventItemDelete itemType:itemType itemID:itemId];
    dispatch_async(self.serialQueue, ^{
        [self trackEventObject:object properties:nil];
    });
}

#pragma mark - track event

- (void)profile:(NSString *)type properties:(NSDictionary *)properties {
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:type];

    [self trackEventObject:object properties:properties];
}

- (NSDictionary *)identities {
    return self.identifier.identities;
}

- (void)bind:(NSString *)key value:(NSString *)value {
    SABindEventObject *object = [[SABindEventObject alloc] initWithEventId:kSAEventNameBind];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForBind:key value:value]) {
            return;
        }
        [self.identifier bindIdentity:key value:value];
        [self trackEventObject:object properties:nil];
    });
}

- (void)unbind:(NSString *)key value:(NSString *)value {
    SAUnbindEventObject *object = [[SAUnbindEventObject alloc] initWithEventId:kSAEventNameUnbind];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForUnbind:key value:value]) {
            return;
        }
        [self.identifier unbindIdentity:key value:value];
        [self trackEventObject:object properties:nil];
    });
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:event];

    [self trackEventObject:object properties:propertieDict];
}

- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    [_network setCookie:cookie isEncoded:encode];
}

- (NSString *)getCookieWithDecode:(BOOL)decode {
    return [_network cookieWithDecoded:decode];
}

- (BOOL)checkEventName:(NSString *)eventName {
    NSError *error = nil;
    [SAValidator validKey:eventName error:&error];
    if (!error) {
        return YES;
    }
    SALogError(@"%@", error.localizedDescription);
    if (error.code == SAValidatorErrorInvalid || error.code == SAValidatorErrorOverflow) {
        return YES;
    }
    return NO;
}

- (nullable NSString *)trackTimerStart:(NSString *)event {
    if (![self checkEventName:event]) {
        return nil;
    }
    NSString *eventId = [_trackTimer generateEventIdByEventName:event];
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerStart:eventId currentSysUpTime:currentSysUpTime];
    });
    return eventId;
}

- (void)trackTimerEnd:(NSString *)event {
    [self trackTimerEnd:event withProperties:nil];
}

- (void)trackTimerEnd:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    // trackTimerEnd 事件需要支持新渠道匹配功能，且用户手动调用 trackTimerEnd 应归为手动埋点
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:event];

    [self trackEventObject:object properties:propertyDict];
}

- (void)trackTimerPause:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerPause:event currentSysUpTime:currentSysUpTime];
    });
}

- (void)trackTimerResume:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerResume:event currentSysUpTime:currentSysUpTime];
    });
}

- (void)removeTimer:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerRemove:event];
    });
}

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer clearAllEventTimers];
    });
}

- (void)identify:(NSString *)anonymousId {
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier identify:anonymousId]) {
            return;
        }
        // 其他 SDK 接收匿名 ID 修改通知，例如 AB，SF
        if (!self.loginId) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_IDENTIFY_NOTIFICATION object:nil];
        }
    });
}

- (NSString *)libVersion {
    return VERSION;
}

+ (NSString *)libVersion {
    return VERSION;
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    dispatch_async(self.serialQueue, ^{
        SASuperPropertyPlugin *superPropertyPlugin = (SASuperPropertyPlugin *)[[SAPropertyPluginManager sharedInstance] pluginsWithPluginClass:SASuperPropertyPlugin.class];

        if (superPropertyPlugin) {
            [superPropertyPlugin registerSuperProperties:propertyDict];
        }
    });
}

- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties {
    SADynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [SADynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
    [dynamicSuperPropertyPlugin registerDynamicSuperPropertiesBlock:dynamicSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        SASuperPropertyPlugin *superPropertyPlugin = (SASuperPropertyPlugin *)[[SAPropertyPluginManager sharedInstance] pluginsWithPluginClass:SASuperPropertyPlugin.class];
        if (superPropertyPlugin) {
            [superPropertyPlugin unregisterSuperProperty:property];
        }
    });
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        SASuperPropertyPlugin *superPropertyPlugin = (SASuperPropertyPlugin *)[[SAPropertyPluginManager sharedInstance] pluginsWithPluginClass:SASuperPropertyPlugin.class];
        if (superPropertyPlugin) {
            [superPropertyPlugin clearSuperProperties];
        }
    });
}

- (NSDictionary *)currentSuperProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    void(^block)(void) = ^{
        NSDictionary *dic = [[SAPropertyPluginManager sharedInstance] currentPropertiesForPluginClasses:@[[SASuperPropertyPlugin class]]];
        [properties addEntriesFromDictionary:dic];
    };
    if (sensorsdata_is_same_queue(self.serialQueue)) {
        block();
    } else {
        dispatch_sync(self.serialQueue, block);
    }
    return properties;
}

- (void)trackEventCallback:(BOOL (^)(NSString *eventName, NSMutableDictionary<NSString *, id> *properties))callback {
    if (!callback) {
        return;
    }
    SALogDebug(@"SDK have set trackEvent callBack");
    dispatch_async(self.serialQueue, ^{
        self.trackEventCallback = callback;
    });
}

- (void)registerLimitKeys:(NSDictionary<SALimitKey, NSString *> *)keys {
    [SALimitKeyManager registerLimitKeys:keys];
}

- (void)registerPropertyPlugin:(SAPropertyPlugin *)plugin {
    dispatch_async(self.serialQueue, ^{
        [SAPropertyPluginManager.sharedInstance registerPropertyPlugin:plugin];
    });
}

#pragma mark - Local caches

- (void)startFlushTimer {
    SALogDebug(@"starting flush timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer && [self.timer isValid]) {
            return;
        }

        if (![SAApplication isAppExtension] && self.appLifecycle.state != SAAppLifecycleStateStart) {
            return;
        }

        if ([SAModuleManager.sharedInstance isDisableSDK]) {
            return;
        }
        
        if (self.configOptions.flushInterval > 0) {
            double interval = self.configOptions.flushInterval > 100 ? (double)self.configOptions.flushInterval / 1000.0 : 0.1f;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
        }
        self.timer = nil;
    });
}

- (NSString *)getLastScreenUrl {
    return [SAReferrerManager sharedInstance].referrerURL;
}

- (void)clearReferrerWhenAppEnd {
    [SAReferrerManager sharedInstance].isClearReferrer = YES;
}

- (NSDictionary *)getLastScreenTrackProperties {
    return [SAReferrerManager sharedInstance].referrerProperties;
}

- (SensorsAnalyticsDebugMode)debugMode {
    return self.configOptions.debugMode;
}

#pragma mark - SensorsData  Analytics

- (void)profilePushKey:(NSString *)pushTypeKey pushId:(NSString *)pushId {
    if ([pushTypeKey isKindOfClass:NSString.class] && pushTypeKey.length && [pushId isKindOfClass:NSString.class] && pushId.length) {
        NSString * keyOfPushId = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
        NSString * valueOfPushId = [[SAStoreManager sharedInstance] stringForKey:keyOfPushId];
        NSString * newValueOfPushId = [NSString stringWithFormat:@"%@_%@", self.distinctId, pushId];
        if (![valueOfPushId isEqualToString:newValueOfPushId]) {
            [self set:@{pushTypeKey:pushId}];
            [[SAStoreManager sharedInstance] setObject:newValueOfPushId forKey:keyOfPushId];
        }
    }
}

- (void)profileUnsetPushKey:(NSString *)pushTypeKey {
    NSAssert(([pushTypeKey isKindOfClass:[NSString class]] && pushTypeKey.length), @"pushTypeKey should be a non-empty string object!!!❌❌❌");
    NSString *localKey = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
    NSString *localValue = [[SAStoreManager sharedInstance] stringForKey:localKey];
    if ([localValue hasPrefix:self.distinctId]) {
        [self unset:pushTypeKey];
        [[SAStoreManager sharedInstance] removeObjectForKey:localKey];
    }
}

- (void)set:(NSDictionary *)profileDict {
    if (profileDict) {
        [self profile:kSAProfileSet properties:profileDict];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    if (profileDict) {
        [self profile:kSAProfileSetOnce properties:profileDict];
    }
}

- (void)set:(NSString *) profile to:(id)content {
    if (profile && content) {
        [self profile:kSAProfileSet properties:@{profile: content}];
    }
}

- (void)setOnce:(NSString *) profile to:(id)content {
    if (profile && content) {
        [self profile:kSAProfileSetOnce properties:@{profile: content}];
    }
}

- (void)unset:(NSString *) profile {
    if (profile) {
        [self profile:kSAProfileUnset properties:@{profile: @""}];
    }
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    if (profile && amount) {
        SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:kSAProfileIncrement];

        [self trackEventObject:object properties:@{profile: amount}];
    }
}

- (void)increment:(NSDictionary *)profileDict {
    if (profileDict) {
        SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:kSAProfileIncrement];

        [self trackEventObject:object properties:profileDict];
    }
}

- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content {
    if (profile && content) {
        if ([content isKindOfClass:[NSSet class]] || [content isKindOfClass:[NSArray class]]) {
            SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:kSAProfileAppend];

            [self trackEventObject:object properties:@{profile: content}];
        }
    }
}

- (void)deleteUser {
    [self profile:kSAProfileDelete properties:@{}];
}

- (void)enableLog:(BOOL)enableLog {
    self.configOptions.enableLog = enableLog;
    [SALog sharedLog].enableLog = enableLog;
    if (!enableLog) {
        return;
    }
    [self enableLoggers];
}

- (void)clearKeychainData {
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAUdidAccount service:kSAService];
}

#pragma mark - setup Flow

- (void)trackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties {
    SAFlowData *input = [[SAFlowData alloc] init];
    input.eventObject = object;
    input.identifier = self.identifier;
    input.properties = [properties sensorsdata_deepCopy];
    [SAFlowManager.sharedInstance startWithFlowID:kSATrackFlowId input:input completion:nil];
}

- (void)flushAllEventRecords {
    [self flushAllEventRecordsWithCompletion:nil];
}

- (void)flushAllEventRecordsWithCompletion:(void(^)(void))completion {

    SAFlowData *input = [[SAFlowData alloc] init];
    input.cookie = [self getCookieWithDecode:NO];
    [SAFlowManager.sharedInstance startWithFlowID:kSAFlushFlowId input:input completion:^(SAFlowData * _Nonnull output) {
        // 上传完成
        if (completion) {
            completion();
        }
    }];
}

- (void)buildDynamicSuperProperties {
    SADynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [SADynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
    [dynamicSuperPropertyPlugin buildDynamicSuperProperties];
}

#pragma mark - RemoteConfig

/// 远程控制通知回调需要在所有其他通知之前调用
/// 注意⚠️：不要随意调整通知添加顺序
- (void)addRemoteConfigObservers {
    if (self.configOptions.disableSDK) {
        return;
    }
#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteConfigManagerModelChanged:) name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
#endif
}

- (void)remoteConfigManagerModelChanged:(NSNotification *)sender {
    @try {
        BOOL isDisableDebugMode = [[sender.object valueForKey:@"disableDebugMode"] boolValue];
        if (isDisableDebugMode) {
            self.configOptions.debugMode = SensorsAnalyticsDebugOff;
        }

        BOOL isDisableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
        if (isDisableSDK) {
            [self stopFlushTimer];
            [self removeWebViewUserAgent];
            // 停止采集数据之后 flush 本地数据
            [self flush];
        } else {
            [self startFlushTimer];
            [self appendWebViewUserAgent];
        }
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

- (void)removeWebViewUserAgent {
    if (!self.addWebViewUserAgent) {
        // 没有开启老版打通
        return;
    }
    
    NSString *currentUserAgent = [SACommonUtility currentUserAgent];
    if (![currentUserAgent containsString:self.addWebViewUserAgent]) {
        return;
    }
    
    NSString *newUserAgent = [currentUserAgent stringByReplacingOccurrencesOfString:self.addWebViewUserAgent withString:@""];
    self.userAgent = newUserAgent;
    [SACommonUtility saveUserAgent:self.userAgent];
}

- (void)appendWebViewUserAgent {
    if (!self.addWebViewUserAgent) {
        // 没有开启老版打通
        return;
    }

    if ([SAModuleManager.sharedInstance isDisableSDK]) {
        return;
    }

    NSString *currentUserAgent = [SACommonUtility currentUserAgent];
    if ([currentUserAgent containsString:self.addWebViewUserAgent]) {
        return;
    }
    
    NSMutableString *newUserAgent = [NSMutableString string];
    if (currentUserAgent) {
        [newUserAgent appendString:currentUserAgent];
    }
    [newUserAgent appendString:self.addWebViewUserAgent];
    self.userAgent = newUserAgent;
    [SACommonUtility saveUserAgent:self.userAgent];
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo {
    [self trackFromH5WithEvent:eventInfo enableVerify:NO];
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify {
    if (!eventInfo) {
        return;
    }
    NSMutableDictionary *eventDict = [SAJSONUtil JSONObjectWithString:eventInfo options:NSJSONReadingMutableContainers];
    if (!eventDict) {
        return;
    }

    if (enableVerify) {
        NSString *serverUrl = eventDict[@"server_url"];
        if (![self.network isSameProjectWithURLString:serverUrl]) {
            SALogError(@"Server_url verified faild, Web event lost! Web server_url = '%@'", serverUrl);
            return;
        }
    }

    SABaseEventObject *object = [SAEventObjectFactory eventObjectWithH5Event:eventDict];
    dispatch_async(self.serialQueue, ^{

        NSString *visualProperties = eventDict[kSAEventProperties][kSAAppVisualProperties];
        // 是否包含自定义属性配置，根据配置采集 App 属性内容
        if (!visualProperties || ![object.event isEqualToString:kSAEventNameWebClick]) {
            [self trackFromH5WithEventObject:object properties:nil];
            return;
        }

        NSData *data = [[NSData alloc] initWithBase64EncodedString:visualProperties options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSArray <NSDictionary *> *visualPropertyConfigs = [SAJSONUtil JSONObjectWithData:data];

        // 查询 App 自定义属性值
        [SAModuleManager.sharedInstance queryVisualPropertiesWithConfigs:visualPropertyConfigs completionHandler:^(NSDictionary *_Nullable properties) {

            // 切换到 serialQueue 执行
            dispatch_async(self.serialQueue, ^{
                [self trackFromH5WithEventObject:object properties:properties];
            });
        }];
    });
}

- (void)trackFromH5WithEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties {
    if (object.isSignUp) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGIN_NOTIFICATION object:nil];
    }
    [self trackEventObject:object properties:properties];
}

@end

#pragma mark - Deprecated
@implementation SensorsAnalyticsSDK (Deprecated)

// 广告 SDK 调用，暂时保留
- (void)asyncTrackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties {
    [self trackEventObject:object properties:properties];
}

- (NSInteger)flushInterval {
    @synchronized(self) {
        return self.configOptions.flushInterval;
    }
}

- (void)setFlushInterval:(NSInteger)interval {
    @synchronized(self) {
        self.configOptions.flushInterval = interval;
    }
    [self flush];
    [self stopFlushTimer];
    [self startFlushTimer];
}

- (NSInteger)flushBulkSize {
    @synchronized(self) {
        return self.configOptions.flushBulkSize;
    }
}

- (void)setFlushBulkSize:(NSInteger)bulkSize {
    @synchronized(self) {
        self.configOptions.flushBulkSize = bulkSize;
    }
}

- (void)setMaxCacheSize:(NSInteger)maxCacheSize {
    @synchronized(self) {
        self.configOptions.maxCacheSize = maxCacheSize;
    };
}

- (NSInteger)maxCacheSize {
    @synchronized(self) {
        return self.configOptions.maxCacheSize;
    };
}

- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType {
    @synchronized (self) {
        self.configOptions.flushNetworkPolicy = networkType;
    }
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    self.configOptions.debugMode = debugMode;
}

- (void)trackTimer:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitMilliseconds];
}

- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerStart:event timeUnit:timeUnit currentSysUpTime:currentSysUpTime];
    });
}

@end
