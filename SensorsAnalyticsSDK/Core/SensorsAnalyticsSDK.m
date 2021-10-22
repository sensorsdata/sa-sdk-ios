//  SensorsAnalyticsSDK.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK.h"
#import "SAAppExtensionDataManager.h"
#import "SAKeyChainItemWrapper.h"
#import "SACommonUtility.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SATrackTimer.h"
#import "SAReachability.h"
#import "SAEventTracker.h"
#import "SAIdentifier.h"
#import "SAPresetProperty.h"
#import "SAValidator.h"
#import "SALog+Private.h"
#import "SAConsoleLogger.h"
#import "SAModuleManager.h"
#import "SAAppLifecycle.h"
#import "SAReferrerManager.h"
#import "SAProfileEventObject.h"
#import "SAJSONUtil.h"
#import "SAApplication.h"

#define VERSION @"4.0.0"

void *SensorsAnalyticsQueueTag = &SensorsAnalyticsQueueTag;

static dispatch_once_t sdkInitializeOnceToken;
static SensorsAnalyticsSDK *sharedInstance = nil;

@interface SensorsAnalyticsSDK()

// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;

@property (nonatomic, strong) SANetwork *network;

@property (nonatomic, strong) SAEventTracker *eventTracker;

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

@property (nonatomic, strong) SAPresetProperty *presetProperty;

@property (nonatomic, strong) SASuperProperty *superProperty;

@property (atomic, strong) SAConsoleLogger *consoleLogger;

@property (nonatomic, strong) SAAppLifecycle *appLifecycle;

@end

@implementation SensorsAnalyticsSDK

#pragma mark - Initialization
+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions {
    NSAssert(sensorsdata_is_same_queue(dispatch_get_main_queue()), @"神策 iOS SDK 必须在主线程里进行初始化，否则会引发无法预料的问题（比如丢失 $AppStart 事件）。");

    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[SensorsAnalyticsSDK alloc] initWithConfigOptions:configOptions];
        [SAModuleManager startWithConfigOptions:sharedInstance.configOptions];
        [sharedInstance addAppLifecycleObservers];
    });
}

+ (SensorsAnalyticsSDK *_Nullable)sharedInstance {
    NSAssert(sharedInstance, @"请先使用 startWithConfigOptions: 初始化 SDK");
    if ([SAModuleManager.sharedInstance isDisableSDK]) {
        SALogDebug(@"SDK is disabled");
        return nil;
    }
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sdkInstance {
    NSAssert(sharedInstance, @"请先使用 startWithConfigOptions: 初始化 SDK");
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
    SALogInfo(@"SensorsAnalyticsSDK enabled");
}

- (instancetype)initWithConfigOptions:(nonnull SAConfigOptions *)configOptions {
    @try {
        self = [super init];
        if (self) {
            _configOptions = [configOptions copy];
            _appLifecycle = [[SAAppLifecycle alloc] init];
            
            _people = [[SensorsAnalyticsPeople alloc] init];

            NSString *serialQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.serialQueue.%p", self];
            _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_serialQueue, SensorsAnalyticsQueueTag, &SensorsAnalyticsQueueTag, NULL);

            NSString *readWriteQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.readWriteQueue.%p", self];
            _readWriteQueue = dispatch_queue_create([readWriteQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);

            _network = [[SANetwork alloc] init];

            _eventTracker = [[SAEventTracker alloc] initWithQueue:_serialQueue];
            _trackTimer = [[SATrackTimer alloc] init];

            _identifier = [[SAIdentifier alloc] initWithQueue:_readWriteQueue];
            
            _presetProperty = [[SAPresetProperty alloc] initWithQueue:_readWriteQueue libVersion:[self libVersion]];
            
            _superProperty = [[SASuperProperty alloc] init];

            if (!_configOptions.disableSDK) {
                if (_configOptions.enableLog) {
                    [self enableLog:_configOptions.enableLog];
                }
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
        }
        
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return [NSDictionary dictionaryWithDictionary:[self.presetProperty currentPresetProperties]];
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
    return self.network.serverURL.absoluteString;
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
    SASignUpEventObject *object = [[SASignUpEventObject alloc] initWithEventId:kSAEventNameSignUp];
    object.dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidLoginId:loginId]) {
            return;
        }
        [self.identifier login:loginId];
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGIN_NOTIFICATION object:nil];
        [self trackEventObject:object properties:properties];
    });
}

- (void)logout {
    dispatch_async(self.serialQueue, ^{
        if (!self.loginId) {
            return;
        }
        [self.identifier logout];
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGOUT_NOTIFICATION object:nil];
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
    dispatch_async(self.serialQueue, ^{
        [self.eventTracker flushAllEventRecords];
    });
}

- (void)deleteAll {
    dispatch_async(self.serialQueue, ^{
        [self.eventTracker.eventStore deleteAllRecords];
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
            // 上传所有的数据
            [self.eventTracker flushAllEventRecordsWithCompletion:^{
                // 结束后台任务
                endBackgroundTask();
            }];
        });
#else
        dispatch_async(self.serialQueue, ^{
            // 上传所有的数据
            [self.eventTracker flushAllEventRecords];
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
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    itemDict[kSAEventType] = SA_EVENT_ITEM_SET;
    itemDict[SA_EVENT_ITEM_TYPE] = itemType;
    itemDict[SA_EVENT_ITEM_ID] = itemId;

    dispatch_async(self.serialQueue, ^{
        [self trackItems:itemDict properties:propertyDict];
    });
}

- (void)itemDeleteWithType:(NSString *)itemType itemId:(NSString *)itemId {
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    itemDict[kSAEventType] = SA_EVENT_ITEM_DELETE;
    itemDict[SA_EVENT_ITEM_TYPE] = itemType;
    itemDict[SA_EVENT_ITEM_ID] = itemId;
    
    dispatch_async(self.serialQueue, ^{
        [self trackItems:itemDict properties:nil];
    });
}

- (void)trackItems:(nullable NSDictionary <NSString *, id> *)itemDict properties:(nullable NSDictionary <NSString *, id> *)propertyDict {
    //item_type 必须为合法变量名
    NSString *itemType = itemDict[SA_EVENT_ITEM_TYPE];
    if (itemType.length == 0 || ![SAValidator isValidKey:itemType]) {
        NSString *errMsg = [NSString stringWithFormat:@"item_type name[%@] not valid", itemType];
        SALogError(@"%@", errMsg);
        [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
        return;
    }

    NSString *itemId = itemDict[SA_EVENT_ITEM_ID];
    if (itemId.length == 0 || itemId.length > 255) {
        SALogError(@"%@ max length of item_id is 255, item_id: %@", self, itemId);
        return;
    }
    
    // 校验 properties
    NSError *error = nil;
    propertyDict = [SAPropertyValidator validProperties:[propertyDict copy] error:&error];
    if (error) {
        SALogError(@"%@", error.localizedDescription);
        SALogError(@"%@ failed to item properties", self);
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
        return;
    }
    
    NSMutableDictionary *itemProperties = [NSMutableDictionary dictionaryWithDictionary:itemDict];
    
    // 处理 $project
    NSMutableDictionary *propertyMDict = [NSMutableDictionary dictionaryWithDictionary:propertyDict];
    id project = propertyMDict[kSAEventCommonOptionalPropertyProject];
    if (project) {
        itemProperties[kSAEventProject] = project;
        [propertyMDict removeObjectForKey:kSAEventCommonOptionalPropertyProject];
    }
    
    if (propertyMDict.count > 0) {
        itemProperties[kSAEventProperties] = propertyMDict;
    }
    
    itemProperties[kSAEventLib] = [self.presetProperty libPropertiesWithLibMethod:kSALibMethodCode];

    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    itemProperties[kSAEventTime] = timeStamp;

    SALogDebug(@"\n【track event】:\n%@", itemProperties);

    [self.eventTracker trackEvent:itemProperties];
}
#pragma mark - track event
- (void)asyncTrackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties {
    object.dynamicSuperProperties = [self.superProperty acquireDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        [self trackEventObject:object properties:properties];
    });
}

- (void)trackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties {
    // 1. 远程控制校验
    if ([SAModuleManager.sharedInstance isIgnoreEventObject:object]) {
        return;
    }

    // 2. 事件名校验
    NSError *error = nil;
    [object validateEventWithError:&error];
    if (error) {
        SALogError(@"%@", error.localizedDescription);
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
        return;
    }

    // 3. 设置用户关联信息
    NSString *anonymousId = self.anonymousId;
    object.distinctId = self.distinctId;
    object.loginId = self.loginId;
    object.anonymousId = anonymousId;
    object.originalId = anonymousId;

    // 4. 添加属性
    [object addEventProperties:self.presetProperty.automaticProperties];
    [object addSuperProperties:self.superProperty.currentSuperProperties];
    [object addEventProperties:object.dynamicSuperProperties];
    [object addEventProperties:self.presetProperty.currentNetworkProperties];
    NSNumber *eventDuration = [self.trackTimer eventDurationFromEventId:object.eventId currentSysUpTime:object.currentSystemUpTime];
    [object addDurationProperty:eventDuration];
    [object addLatestUtmProperties:SAModuleManager.sharedInstance.latestUtmProperties];
    [object addChannelProperties:[SAModuleManager.sharedInstance channelInfoWithEvent:object.event]];

    [object addReferrerTitleProperty:[SAReferrerManager sharedInstance].referrerTitle];

    // 5. 添加的自定义属性需要校验
    [object addCustomProperties:properties error:&error];
    [object addModuleProperties:@{kSAEventPresetPropertyIsFirstDay: @(self.presetProperty.isFirstDay)}];
    [object addModuleProperties:SAModuleManager.sharedInstance.properties];
    // 公共属性, 动态公共属性, 自定义属性不允许修改 $device_id 属性, 因此需要将修正逻操作放在所有属性添加后
    [object correctDeviceID:self.presetProperty.deviceID];

    if (error) {
        SALogError(@"%@", error.localizedDescription);
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
        return;
    }

    // 6. trackEventCallback 接口调用
    if (![self willEnqueueWithObject:object]) {
        return;
    }

    // 7. 发送通知 & 事件采集
    NSDictionary *result = [object jsonObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_NOTIFICATION object:nil userInfo:result];
    [self.eventTracker trackEvent:result isSignUp:object.isSignUp];
    SALogDebug(@"\n【track event】:\n%@", result);
}

- (BOOL)willEnqueueWithObject:(SABaseEventObject *)obj {
    NSString *eventName = obj.event;
    if (!self.trackEventCallback || !eventName) {
        return YES;
    }
    BOOL willEnque = self.trackEventCallback(eventName, obj.properties);
    if (!willEnque) {
        SALogDebug(@"\n【track event】: %@ can not enter database.", eventName);
        return NO;
    }
    // 校验 properties
    NSError *error = nil;
    NSMutableDictionary *properties = [SAPropertyValidator validProperties:obj.properties error:&error];
    if (error) {
        SALogError(@"%@ failed to track event.", self);
        return NO;
    }
    obj.properties = properties;
    return YES;
}

- (NSDictionary<NSString *, id> *)willEnqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    if (!self.trackEventCallback || !e[@"event"]) {
        return [e copy];
    }
    NSMutableDictionary *event = [e mutableCopy];
    NSMutableDictionary<NSString *, id> *originProperties = event[@"properties"];
    BOOL isIncluded = self.trackEventCallback(event[@"event"], originProperties);
    if (!isIncluded) {
        SALogDebug(@"\n【track event】: %@ can not enter database.", event[@"event"]);
        return nil;
    }
    // 校验 properties
    NSError *error = nil;
    NSDictionary *validProperties = [SAPropertyValidator validProperties:originProperties error:&error];
    if (error) {
        SALogError(@"%@", error.localizedDescription);
        SALogError(@"%@ failed to track event.", self);
        [SAModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
        return nil;
    }
    event[@"properties"] = validProperties;
    return event;
}

- (void)profile:(NSString *)type properties:(NSDictionary *)properties {
    SAProfileEventObject *object = [[SAProfileEventObject alloc] initWithType:type];
    [self asyncTrackEventObject:object properties:properties];
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:event];
    [self asyncTrackEventObject:object properties:propertieDict];
}

- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    [_network setCookie:cookie isEncoded:encode];
}

- (NSString *)getCookieWithDecode:(BOOL)decode {
    return [_network cookieWithDecoded:decode];
}

- (BOOL)checkEventName:(NSString *)eventName {
    if ([SAValidator isValidKey:eventName]) {
        return YES;
    }
    NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", eventName];
    SALogError(@"%@", errMsg);
    [SAModuleManager.sharedInstance showDebugModeWarning:errMsg];
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
    [self asyncTrackEventObject:object properties:propertyDict];
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

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    dispatch_async(self.serialQueue, ^{
        [self.superProperty registerSuperProperties:propertyDict];
    });
}

- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties {
    [self.superProperty registerDynamicSuperProperties:dynamicSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        [self.superProperty unregisterSuperProperty:property];
    });
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        [self.superProperty clearSuperProperties];
    });
}

- (NSDictionary *)currentSuperProperties {
    return [self.superProperty currentSuperProperties];
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
    return SAModuleManager.sharedInstance.debugMode;
}

- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion {
    @try {
        if (groupIdentifier == nil || [groupIdentifier isEqualToString:@""]) {
            return;
        }
        NSArray *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier:groupIdentifier];
        if (eventArray) {
            for (NSDictionary *dict in eventArray) {
                SACustomEventObject *object = [[SACustomEventObject alloc] initWithEventId:dict[kSAEventName]];
                [self asyncTrackEventObject:object properties:dict[kSAEventProperties]];
            }
            [[SAAppExtensionDataManager sharedInstance] deleteEventsWithGroupIdentifier:groupIdentifier];
            if (completion) {
                completion(groupIdentifier, eventArray);
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - SensorsData  Analytics

- (void)set:(NSDictionary *)profileDict {
    [[self people] set:profileDict];
}

- (void)profilePushKey:(NSString *)pushTypeKey pushId:(NSString *)pushId {
    if ([pushTypeKey isKindOfClass:NSString.class] && pushTypeKey.length && [pushId isKindOfClass:NSString.class] && pushId.length) {
        NSString * keyOfPushId = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
        NSString * valueOfPushId = [NSUserDefaults.standardUserDefaults valueForKey:keyOfPushId];
        NSString * newValueOfPushId = [NSString stringWithFormat:@"%@_%@", self.distinctId, pushId];
        if (![valueOfPushId isEqualToString:newValueOfPushId]) {
            [self set:@{pushTypeKey:pushId}];
            [NSUserDefaults.standardUserDefaults setValue:newValueOfPushId forKey:keyOfPushId];
        }
    }
}

- (void)profileUnsetPushKey:(NSString *)pushTypeKey {
    NSAssert(([pushTypeKey isKindOfClass:[NSString class]] && pushTypeKey.length), @"pushTypeKey should be a non-empty string object!!!❌❌❌");
    NSString *localKey = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
    NSString *localValue = [NSUserDefaults.standardUserDefaults valueForKey:localKey];
    if ([localValue hasPrefix:self.distinctId]) {
        [self unset:pushTypeKey];
        [NSUserDefaults.standardUserDefaults removeObjectForKey:localKey];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    [[self people] setOnce:profileDict];
}

- (void)set:(NSString *) profile to:(id)content {
    [[self people] set:profile to:content];
}

- (void)setOnce:(NSString *) profile to:(id)content {
    [[self people] setOnce:profile to:content];
}

- (void)unset:(NSString *) profile {
    [[self people] unset:profile];
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    [[self people] increment:profile by:amount];
}

- (void)increment:(NSDictionary *)profileDict {
    [[self people] increment:profileDict];
}

- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content {
    if ([content isKindOfClass:[NSSet class]] || [content isKindOfClass:[NSArray class]]) {
        [[self people] append:profile by:content];
    }
}

- (void)deleteUser {
    [[self people] deleteUser];
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
            SAModuleManager.sharedInstance.debugMode = SensorsAnalyticsDebugOff;
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

    dispatch_async(self.serialQueue, ^{
        NSString *type = eventDict[kSAEventType];
        NSMutableDictionary *propertiesDict = eventDict[kSAEventProperties];

        if ([type isEqualToString:kSAEventTypeSignup]) {
            eventDict[@"original_id"] = self.anonymousId;
        } else {
            eventDict[kSAEventDistinctId] = self.distinctId;
        }
        eventDict[kSAEventTrackId] = @(arc4random());

        NSMutableDictionary *libMDic = eventDict[kSAEventLib];
        //update lib $app_version from super properties
        NSDictionary *superProperties = [self.superProperty currentSuperProperties];
        id appVersion = superProperties[kSAEventPresetPropertyAppVersion] ? : self.presetProperty.appVersion;
        if (appVersion) {
            libMDic[kSAEventPresetPropertyAppVersion] = appVersion;
        }

        NSMutableDictionary *automaticPropertiesCopy = [NSMutableDictionary dictionaryWithDictionary:self.presetProperty.automaticProperties];
        [automaticPropertiesCopy removeObjectForKey:kSAEventPresetPropertyLib];
        [automaticPropertiesCopy removeObjectForKey:kSAEventPresetPropertyLibVersion];

        if ([type isEqualToString:kSAEventTypeTrack] || [type isEqualToString:kSAEventTypeSignup]) {
            // track / track_signup 类型的请求，还是要加上各种公共property
            // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties,dynamicSuperPropertiesDict,propertieDict
            [propertiesDict addEntriesFromDictionary:automaticPropertiesCopy];

            NSDictionary *dynamicSuperPropertiesDict = [self.superProperty acquireDynamicSuperProperties];
            [propertiesDict addEntriesFromDictionary:self.superProperty.currentSuperProperties];
            [propertiesDict addEntriesFromDictionary:dynamicSuperPropertiesDict];

            // 每次 track 时手机网络状态
            [propertiesDict addEntriesFromDictionary:[self.presetProperty currentNetworkProperties]];
        }

        NSString *visualProperties = eventDict[kSAEventProperties][@"sensorsdata_app_visual_properties"];
        // 是否包含自定义属性配置
        if (!visualProperties || ![eventDict[kSAEventName] isEqualToString:kSAEventNameWebClick]) {
            eventDict[kSAEventProperties] = propertiesDict;
            [self trackFromH5WithEventDict:eventDict];
            return;
        }

        NSData *data = [[NSData alloc] initWithBase64EncodedString:visualProperties options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSArray <NSDictionary *> *visualPropertyConfigs = [SAJSONUtil JSONObjectWithData:data];

        // 查询 App 自定义属性值
        NSDate *currentTime = [NSDate date];
        [SAModuleManager.sharedInstance queryVisualPropertiesWithConfigs:visualPropertyConfigs completionHandler:^(NSDictionary *_Nullable properties) {

            // 切换到 serialQueue 执行
            dispatch_async(self.serialQueue, ^{
                if (properties.count > 0) {
                    [propertiesDict addEntriesFromDictionary:properties];
                }

                // 设置 $time，自定义时间，防止事件序列错误
                if (!propertiesDict[kSAEventCommonOptionalPropertyTime]) {
                    propertiesDict[kSAEventCommonOptionalPropertyTime] = currentTime;
                }
                propertiesDict[@"sensorsdata_app_visual_properties"] = nil;
                eventDict[kSAEventProperties] = propertiesDict;
                [self trackFromH5WithEventDict:eventDict];
            });
        }];
    });
}
- (void)trackFromH5WithEventDict:(NSMutableDictionary *)eventDict {
    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    NSString *type = eventDict[kSAEventType];
    @try {
        // 校验 properties
        NSError *validError = nil;
        NSMutableDictionary *propertiesDict = [SAPropertyValidator validProperties:eventDict[kSAEventProperties] error:&validError];
        if (validError) {
            SALogError(@"%@", validError.localizedDescription);
            SALogError(@"%@ failed to track event from H5.", self);
            [SAModuleManager.sharedInstance showDebugModeWarning:validError.localizedDescription];
            return;
        }

        [eventDict removeObjectForKey:@"_nocache"];
        [eventDict removeObjectForKey:@"server_url"];
        
        if (([type isEqualToString:kSAEventTypeTrack] || [type isEqualToString:kSAEventTypeSignup])) {
            //  是否首日访问
            if ([type isEqualToString:kSAEventTypeTrack]) {
                propertiesDict[kSAEventPresetPropertyIsFirstDay] = @([self.presetProperty isFirstDay]);
            }
            [propertiesDict removeObjectForKey:@"_nocache"];

            // 添加 DeepLink 来源渠道参数。优先级最高，覆盖 H5 传过来的同名字段
            [propertiesDict addEntriesFromDictionary:SAModuleManager.sharedInstance.latestUtmProperties];
        }

        // $project & $token
        NSString *project = propertiesDict[kSAEventCommonOptionalPropertyProject];
        NSString *token = propertiesDict[kSAEventCommonOptionalPropertyToken];
        id timeNumber = propertiesDict[kSAEventCommonOptionalPropertyTime];

        if (project) {
            [propertiesDict removeObjectForKey:kSAEventCommonOptionalPropertyProject];
            eventDict[kSAEventProject] = project;
        }
        if (token) {
            [propertiesDict removeObjectForKey:kSAEventCommonOptionalPropertyToken];
            eventDict[kSAEventToken] = token;
        }
        if (timeNumber) {     //包含 $time
            NSNumber *customTime = nil;
            if ([timeNumber isKindOfClass:[NSDate class]]) {
                customTime = @([(NSDate *)timeNumber timeIntervalSince1970] * 1000);
            } else if ([timeNumber isKindOfClass:[NSNumber class]]) {
                customTime = timeNumber;
            }

            if (!customTime) {
                SALogError(@"H5 $time '%@' invalid，Please check the value", timeNumber);
            } else if ([customTime compare:@(kSAEventCommonOptionalPropertyTimeInt)] == NSOrderedAscending) {
                SALogError(@"H5 $time error %@，Please check the value", timeNumber);
            } else {
                timeStamp = @([customTime unsignedLongLongValue]);
            }
            [propertiesDict removeObjectForKey:kSAEventCommonOptionalPropertyTime];
        }

        eventDict[kSAEventProperties] = propertiesDict;
        eventDict[kSAEventTime] = timeStamp;

        //JS SDK Data add _hybrid_h5 flag
        eventDict[kSAEventHybridH5] = @(YES);

        NSMutableDictionary *enqueueEvent = [[self willEnqueueWithType:type andEvent:eventDict] mutableCopy];

        if (!enqueueEvent) {
            return;
        }
        // 只有当本地 loginId 不为空时才覆盖 H5 数据
        if (self.loginId) {
            enqueueEvent[kSAEventLoginId] = self.loginId;
        }
        enqueueEvent[kSAEventAnonymousId] = self.anonymousId;

        if ([type isEqualToString:kSAEventTypeSignup]) {
            NSString *newLoginId = eventDict[kSAEventDistinctId];
            if ([self.identifier isValidLoginId:newLoginId]) {
                [self.identifier login:newLoginId];
                enqueueEvent[kSAEventLoginId] = newLoginId;
                [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_H5_NOTIFICATION object:nil userInfo:[enqueueEvent copy]];
                [self.eventTracker trackEvent:enqueueEvent isSignUp:YES];
                SALogDebug(@"\n【track event from H5】:\n%@", enqueueEvent);
                [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGIN_NOTIFICATION object:nil];
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_H5_NOTIFICATION object:nil userInfo:[enqueueEvent copy]];

            eventDict[kSAEventProperties][@"sensorsdata_web_visual_eventName"] = nil;
            [self.eventTracker trackEvent:enqueueEvent];
            SALogDebug(@"\n【track event from H5】:\n%@", enqueueEvent);
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

@end

#pragma mark - People analytics

@implementation SensorsAnalyticsPeople

- (void)set:(NSDictionary *)profileDict {
    if (profileDict) {
        [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_SET properties:profileDict];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    if (profileDict) {
        [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_SET_ONCE properties:profileDict];
    }
}

- (void)set:(NSString *) profile to:(id)content {
    if (profile && content) {
        [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_SET properties:@{profile: content}];
    }
}

- (void)setOnce:(NSString *) profile to:(id)content {
    if (profile && content) {
        [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_SET_ONCE properties:@{profile: content}];
    }
}

- (void)unset:(NSString *) profile {
    if (profile) {
        [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_UNSET properties:@{profile: @""}];
    }
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    if (profile && amount) {
        SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
        [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:@{profile: amount}];
    }
}

- (void)increment:(NSDictionary *)profileDict {
    if (profileDict) {
        SAProfileIncrementEventObject *object = [[SAProfileIncrementEventObject alloc] initWithType:SA_PROFILE_INCREMENT];
        [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:profileDict];
    }
}

- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content {
    if (profile && content) {
        if ([content isKindOfClass:[NSSet class]] || [content isKindOfClass:[NSArray class]]) {
            SAProfileAppendEventObject *object = [[SAProfileAppendEventObject alloc] initWithType:SA_PROFILE_APPEND];
            [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:@{profile: content}];
        }
    }
}

- (void)deleteUser {
    [[SensorsAnalyticsSDK sharedInstance] profile:SA_PROFILE_DELETE properties:@{}];
}

@end

#pragma mark - Deprecated
@implementation SensorsAnalyticsSDK (Deprecated)

- (UInt64)flushInterval {
    @synchronized(self) {
        return self.configOptions.flushInterval;
    }
}

- (void)setFlushInterval:(UInt64)interval {
    @synchronized(self) {
        if (interval < 5 * 1000) {
            interval = 5 * 1000;
        }
        self.configOptions.flushInterval = (NSInteger)interval;
    }
    [self flush];
    [self stopFlushTimer];
    [self startFlushTimer];
}

- (UInt64)flushBulkSize {
    @synchronized(self) {
        return self.configOptions.flushBulkSize;
    }
}

- (void)setFlushBulkSize:(UInt64)bulkSize {
    @synchronized(self) {
        //加上最小值保护，50
        NSInteger newBulkSize = (NSInteger)bulkSize;
        self.configOptions.flushBulkSize = newBulkSize >= 50 ? newBulkSize : 50;
    }
}

- (void)setMaxCacheSize:(UInt64)maxCacheSize {
    @synchronized(self) {
        //防止设置的值太小导致事件丢失
        UInt64 temMaxCacheSize = maxCacheSize > 10000 ? maxCacheSize : 10000;
        self.configOptions.maxCacheSize = (NSInteger)temMaxCacheSize;
    };
}

- (UInt64)maxCacheSize {
    @synchronized(self) {
        return (UInt64)self.configOptions.maxCacheSize;
    };
}

- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType {
    @synchronized (self) {
        self.configOptions.flushNetworkPolicy = networkType;
    }
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    SAModuleManager.sharedInstance.debugMode = debugMode;
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
