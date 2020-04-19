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


#import <Availability.h>
#import <objc/runtime.h>
#include <sys/sysctl.h>
#include <stdlib.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "SAJSONUtil.h"
#import "SAGzipUtility.h"
#import "MessageQueueBySqlite.h"
#import "SAReachability.h"
#import "SASwizzler.h"
#import "SensorsAnalyticsSDK.h"
#import "UIApplication+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SASwizzle.h"
#import "NSString+HashCode.h"
#import "SensorsAnalyticsExceptionHandler.h"
#import "SAURLUtils.h"
#import "SAAppExtensionDataManager.h"
#import "SAAutoTrackUtils.h"

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    #import "SAKeyChainItemWrapper.h"
#endif

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
#import <WebKit/WebKit.h>
#endif

#import "SASDKRemoteConfig.h"
#import "SADeviceOrientationManager.h"
#import "SALocationManager.h"
#import "UIView+AutoTrack.h"
#import "SACommonUtility.h"
#import "SAConstants+Private.h"
#import "UIGestureRecognizer+AutoTrack.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAlertController.h"
#import "SAAuxiliaryToolManager.h"
#import "SAWeakPropertyContainer.h"
#import "SADateFormatter.h"
#import "SALinkHandler.h"
#import "SAFileStore.h"
#import "SATrackTimer.h"
#import "SALog+Private.h"
#import "SAConsoleLogger.h"

#define VERSION @"2.0.4"

static NSUInteger const SA_PROPERTY_LENGTH_LIMITATION = 8191;

static NSString* const SA_JS_GET_APP_INFO_SCHEME = @"sensorsanalytics://getAppInfo";
static NSString* const SA_JS_TRACK_EVENT_NATIVE_SCHEME = @"sensorsanalytics://trackEvent";
//中国运营商 mcc 标识
static NSString* const CARRIER_CHINA_MCC = @"460";

void *SensorsAnalyticsQueueTag = &SensorsAnalyticsQueueTag;

static dispatch_once_t sdkInitializeOnceToken;

@implementation SensorsAnalyticsDebugException

@end

@implementation UIImage (SensorsAnalytics)
- (NSString *)sensorsAnalyticsImageName {
    return objc_getAssociatedObject(self, @"sensorsAnalyticsImageName");
}

- (void)setSensorsAnalyticsImageName:(NSString *)sensorsAnalyticsImageName {
    objc_setAssociatedObject(self, @"sensorsAnalyticsImageName", sensorsAnalyticsImageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end

@implementation UIView (SensorsAnalytics)

- (UIViewController *)sensorsAnalyticsViewController {
    return self.sensorsdata_viewController;
}

//viewID
- (NSString *)sensorsAnalyticsViewID {
    return objc_getAssociatedObject(self, @"sensorsAnalyticsViewID");
}

- (void)setSensorsAnalyticsViewID:(NSString *)sensorsAnalyticsViewID {
    objc_setAssociatedObject(self, @"sensorsAnalyticsViewID", sensorsAnalyticsViewID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

//ignoreView
- (BOOL)sensorsAnalyticsIgnoreView {
    return [objc_getAssociatedObject(self, @"sensorsAnalyticsIgnoreView") boolValue];
}

- (void)setSensorsAnalyticsIgnoreView:(BOOL)sensorsAnalyticsIgnoreView {
    objc_setAssociatedObject(self, @"sensorsAnalyticsIgnoreView", [NSNumber numberWithBool:sensorsAnalyticsIgnoreView], OBJC_ASSOCIATION_ASSIGN);
}

//afterSendAction
- (BOOL)sensorsAnalyticsAutoTrackAfterSendAction {
    return [objc_getAssociatedObject(self, @"sensorsAnalyticsAutoTrackAfterSendAction") boolValue];
}

- (void)setSensorsAnalyticsAutoTrackAfterSendAction:(BOOL)sensorsAnalyticsAutoTrackAfterSendAction {
    objc_setAssociatedObject(self, @"sensorsAnalyticsAutoTrackAfterSendAction", [NSNumber numberWithBool:sensorsAnalyticsAutoTrackAfterSendAction], OBJC_ASSOCIATION_ASSIGN);
}

//viewProperty
- (NSDictionary *)sensorsAnalyticsViewProperties {
    return objc_getAssociatedObject(self, @"sensorsAnalyticsViewProperties");
}

- (void)setSensorsAnalyticsViewProperties:(NSDictionary *)sensorsAnalyticsViewProperties {
    objc_setAssociatedObject(self, @"sensorsAnalyticsViewProperties", sensorsAnalyticsViewProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<SAUIViewAutoTrackDelegate>)sensorsAnalyticsDelegate {
    SAWeakPropertyContainer *container = objc_getAssociatedObject(self, @"sensorsAnalyticsDelegate");
    return container.weakProperty;
}

- (void)setSensorsAnalyticsDelegate:(id<SAUIViewAutoTrackDelegate>)sensorsAnalyticsDelegate {
    SAWeakPropertyContainer *container = [SAWeakPropertyContainer containerWithWeakProperty:sensorsAnalyticsDelegate];
    objc_setAssociatedObject(self, @"sensorsAnalyticsDelegate", container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end


static SensorsAnalyticsSDK *sharedInstance = nil;

@interface SensorsAnalyticsSDK()

// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;

@property (nonatomic, strong) SANetwork *network;

@property (atomic, copy) NSString *originalId;
@property (nonatomic, copy) NSString *anonymousId;
@property (atomic, copy) NSString *loginId;
@property (atomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *superProperties;
@property (nonatomic, strong) SATrackTimer *trackTimer;

@property (nonatomic, strong) NSRegularExpression *propertiesRegex;
@property (nonatomic, copy) NSSet *presetEventNames;

@property (atomic, strong) MessageQueueBySqlite *messageQueue;

@property (nonatomic, strong) NSTimer *timer;

//用户设置的不被AutoTrack的Controllers
@property (nonatomic, strong) NSMutableArray *ignoredViewControllers;
@property (nonatomic, weak) UIViewController *previousTrackViewController;

@property (nonatomic, strong) NSMutableSet<NSString *> *heatMapViewControllers;
@property (nonatomic, strong) NSMutableSet<NSString *> *visualizedAutoTrackViewControllers;

@property (nonatomic, strong) NSMutableArray *ignoredViewTypeList;
@property (nonatomic, copy) NSString *userAgent;

@property (nonatomic, strong) NSMutableSet<NSString *> *trackChannelEventNames;

@property (nonatomic, strong) SASDKRemoteConfig *remoteConfig;
@property (nonatomic, strong) SAConfigOptions *configOptions;

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
@property (nonatomic, strong) SADeviceOrientationManager *deviceOrientationManager;
@property (nonatomic, strong) SADeviceOrientationConfig *deviceOrientationConfig;
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
@property (nonatomic, strong) SALocationManager *locationManager;
@property (nonatomic, strong) SAGPSLocationConfig *locationConfig;
#endif

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;
#endif

@property (nonatomic, copy) void(^reqConfigBlock)(BOOL success , NSDictionary *configDict);
@property (nonatomic, assign) NSUInteger pullSDKConfigurationRetryMaxCount;

@property (nonatomic, copy) NSDictionary<NSString *, id> *(^dynamicSuperProperties)(void);
@property (nonatomic, copy) BOOL (^trackEventCallback)(NSString *, NSMutableDictionary<NSString *, id> *);

///是否为被动启动
@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;
@property (nonatomic, strong) NSMutableArray <UIViewController *> *launchedPassivelyControllers;

/// DeepLink handler
@property (nonatomic, strong) SALinkHandler *linkHandler;

@property (nonatomic, strong) SAConsoleLogger *consoleLogger;

@end

@implementation SensorsAnalyticsSDK {
    SensorsAnalyticsDebugMode _debugMode;
    BOOL _appRelaunched;                // App 从后台恢复
    BOOL _showDebugAlertView;
    UInt8 _debugAlertViewHasShownNumber;
    NSString *_referrerScreenUrl;
    NSDictionary *_lastScreenTrackProperties;
    //进入非活动状态，比如双击 home、系统授权弹框
    BOOL _applicationWillResignActive;
    BOOL _clearReferrerWhenAppEnd;
    SensorsAnalyticsNetworkType _networkTypePolicy;
    NSString *_deviceModel;
    NSString *_osVersion;
}

@synthesize remoteConfig = _remoteConfig;

#pragma mark - Initialization
+ (void)startWithConfigOptions:(SAConfigOptions *)configOptions {
    NSAssert(sensorsdata_is_same_queue(dispatch_get_main_queue()), @"神策 iOS SDK 必须在主线程里进行初始化，否则会引发无法预料的问题（比如丢失 $AppStart 事件）。");
    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[SensorsAnalyticsSDK alloc] initWithConfigOptions:configOptions debugMode:SensorsAnalyticsDebugOff];
    });
}

+ (SensorsAnalyticsSDK *_Nullable)sharedInstance {
    NSAssert(sharedInstance, @"请先使用 startWithConfigOptions: 初始化 SDK");
    if (sharedInstance.remoteConfig.disableSDK) {
        return nil;
    }
    return sharedInstance;
}

- (instancetype)initWithServerURL:(NSString *)serverURL
                 andLaunchOptions:(NSDictionary *)launchOptions
                     andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    @try {
        
        SAConfigOptions * options = [[SAConfigOptions alloc]initWithServerURL:serverURL launchOptions:launchOptions];
        self = [self initWithConfigOptions:options debugMode:debugMode];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    return self;
}

- (instancetype)initWithConfigOptions:(nonnull SAConfigOptions *)configOptions debugMode:(SensorsAnalyticsDebugMode)debugMode {
    @try {
        self = [super init];
        if (self) {
            _configOptions = [configOptions copy];
            
            _networkTypePolicy = SensorsAnalyticsNetworkType3G | SensorsAnalyticsNetworkType4G | SensorsAnalyticsNetworkTypeWIFI;
            
            dispatch_block_t mainThreadBlock = ^(){
                //判断被动启动
                if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
                    self->_launchedPassively = YES;
                }
            };
            sensorsdata_dispatch_main_safe_sync(mainThreadBlock);
            
            _people = [[SensorsAnalyticsPeople alloc] init];
            _debugMode = debugMode;
            
            _network = [[SANetwork alloc] initWithServerURL:[NSURL URLWithString:_configOptions.serverURL]];
            
            _appRelaunched = NO;
            _showDebugAlertView = YES;
            _debugAlertViewHasShownNumber = 0;
            _referrerScreenUrl = nil;
            _lastScreenTrackProperties = nil;
            _applicationWillResignActive = NO;
            _clearReferrerWhenAppEnd = NO;
            _pullSDKConfigurationRetryMaxCount = 3;// SDK 开启关闭功能接口最大重试次数
            _flushBeforeEnterBackground = YES;
            
            NSString *label = [NSString stringWithFormat:@"com.sensorsdata.serialQueue.%p", self];
            _serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_serialQueue, SensorsAnalyticsQueueTag, &SensorsAnalyticsQueueTag, NULL);
            
            NSString *readWriteLabel = [NSString stringWithFormat:@"com.sensorsdata.readWriteQueue.%p", self];
            _readWriteQueue = dispatch_queue_create([readWriteLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            
            NSDictionary *sdkConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_SDK_TRACK_CONFIG];
            [self setSDKWithRemoteConfigDict:sdkConfig];
            
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            _deviceOrientationConfig = [[SADeviceOrientationConfig alloc] init];
#endif
            
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
            _locationConfig = [[SAGPSLocationConfig alloc] init];
#endif
            
            _ignoredViewControllers = [[NSMutableArray alloc] init];
            _ignoredViewTypeList = [[NSMutableArray alloc] init];
            _heatMapViewControllers = [[NSMutableSet alloc] init];
            _visualizedAutoTrackViewControllers = [[NSMutableSet alloc] init];
            _trackChannelEventNames = [[NSMutableSet alloc] init];

             _trackTimer = [[SATrackTimer alloc] init];
            
            // 初始化 LinkHandler 处理 deepLink 相关操作
            _linkHandler = [[SALinkHandler alloc] initWithConfigOptions:configOptions];

            _messageQueue = [[MessageQueueBySqlite alloc] initWithFilePath:[SAFileStore filePath:@"message-v2"]];
            if (self.messageQueue == nil) {
                SALogDebug(@"SqliteException: init Message Queue in Sqlite fail");
            }
            
            NSString *namePattern = @"^([a-zA-Z_$][a-zA-Z\\d_$]{0,99})$";
            _propertiesRegex = [NSRegularExpression regularExpressionWithPattern:namePattern options:NSRegularExpressionCaseInsensitive error:nil];
            _presetEventNames = [NSSet setWithObjects:
                                      SA_EVENT_NAME_APP_START,
                                      SA_EVENT_NAME_APP_START_PASSIVELY ,
                                      SA_EVENT_NAME_APP_END,
                                      SA_EVENT_NAME_APP_VIEW_SCREEN,
                                      SA_EVENT_NAME_APP_CLICK,
                                      SA_EVENT_NAME_APP_SIGN_UP,
                                      SA_EVENT_NAME_APP_CRASHED, nil];

            if (!_launchedPassively) {
                [self startFlushTimer];
            }
            
            // 取上一次进程退出时保存的distinctId、loginId、superProperties
            [self unarchive];
            
            if (self.firstDay == nil) {
                NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
                self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
                [self archiveFirstDay];
            }

            self.automaticProperties = [self collectAutomaticProperties];

            [self startAppEndTimer];
            [self setUpListeners];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self autoTrackAppStart];
            });

            if (_configOptions.enableTrackAppCrash) {
                // Install uncaught exception handlers first
                [[SensorsAnalyticsExceptionHandler sharedHandler] addSensorsAnalyticsInstance:self];
            }
            [self configServerURLWithDebugMode:_debugMode showDebugModeWarning:YES];
            
            if (_configOptions.enableLog) {
                [self enableLog:YES];
            }
        }
        
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    
    return self;
}

- (void)enableLoggers:(BOOL)enableLog {
    if (!self.consoleLogger) {
        SAConsoleLogger *consoleLogger = [[SAConsoleLogger alloc] init];
        [SALog addLogger:consoleLogger];
        self.consoleLogger = consoleLogger;
    }
    self.consoleLogger.enableLog = enableLog;
}

+ (UInt64)getCurrentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (UInt64)getSystemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

+ (NSString *)getUniqueHardwareId {
    NSString *distinctId = NULL;

    // 宏 SENSORS_ANALYTICS_IDFA 定义时，优先使用IDFA
//#if defined(SENSORS_ANALYTICS_IDFA)
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        distinctId = [uuid UUIDString];
        // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
        // 00000000-0000-0000-0000-000000000000
        if (!distinctId || [distinctId hasPrefix:@"00000000"]) {
            distinctId = NULL;
        }
    }
//#endif
    
    // 没有IDFA，则使用IDFV
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    // 没有IDFV，则使用UUID
    if (!distinctId) {
        SALogDebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    return distinctId;
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    if (self.userAgent) {
        return completion(self.userAgent);
    }
#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.wkWebView) {
            dispatch_group_notify(self.loadUAGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                completion(self.userAgent);
            });
        } else {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            self.loadUAGroup = dispatch_group_create();
            dispatch_group_enter(self.loadUAGroup);

            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                if (error || !response) {
                    SALogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    weakSelf.userAgent = response;
                    completion(weakSelf.userAgent);
                }
                weakSelf.wkWebView = nil;
                dispatch_group_leave(weakSelf.loadUAGroup);
            }];
        }
    });
#else
    sensorsdata_dispatch_main_safe_sync(^{
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        completion(self.userAgent);
    });
#endif
}

- (BOOL)shouldTrackViewController:(UIViewController *)controller ofType:(SensorsAnalyticsAutoTrackEventType)type {
    if ([self isViewControllerIgnored:controller]) {
        return NO;
    }
    // UITabBarController 默认包含在黑名单，单独判断，防止 UITabBar 点击事件被忽略
    if (type == SensorsAnalyticsEventTypeAppClick && [controller isKindOfClass:[UITabBarController class]]) {
        return YES;
    }

    return ![self isBlackListContainsViewController:controller];
}

- (BOOL)isBlackListContainsViewController:(UIViewController *)viewController {
    static NSSet *publicClasses = nil;
    static NSSet *privateClasses = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
        //文件路径
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            NSDictionary *ignoredClasses = [NSJSONSerialization JSONObjectWithData:jsonData  options:NSJSONReadingAllowFragments  error:nil];
            publicClasses = [NSSet setWithArray:ignoredClasses[@"public"]];
            privateClasses = [NSSet setWithArray:ignoredClasses[@"private"]];
        } @catch(NSException *exception) {  // json加载和解析可能失败
            SALogError(@"%@ error: %@", self, exception);
        }
    });
    
    //check public ignored classes contains viewController or not
    for (NSString *ignoreClass in publicClasses) {
        if ([viewController isKindOfClass:NSClassFromString(ignoreClass)]) {
            return YES;
        }
    }
    
    //check private ignored classes contains viewController or not
    for (NSString *ignoreClass in privateClasses) {
        if ([ignoreClass isEqualToString:NSStringFromClass([viewController class])]) {
            return YES;
        }
    }
    //neither public nor private ignore classes, then return NO
    return NO;
}

- (NSDictionary *)getPresetProperties {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    @try {
        id app_version = [_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
        if (app_version) {
            [properties setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
        }
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB] forKey:SA_EVENT_COMMON_PROPERTY_LIB];
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION] forKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION];
        [properties setValue:@"Apple" forKey:SA_EVENT_COMMON_PROPERTY_MANUFACTURER];
        [properties setValue:_deviceModel forKey:SA_EVENT_COMMON_PROPERTY_MODEL];
        [properties setValue:@"iOS" forKey:SA_EVENT_COMMON_PROPERTY_OS];
        [properties setValue:_osVersion forKey:SA_EVENT_COMMON_PROPERTY_OS_VERSION];
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT] forKey:SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT];
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH] forKey:SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH];
        NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
        [properties setObject:networkType forKey:SA_EVENT_COMMON_PROPERTY_NETWORK_TYPE];
        if ([networkType isEqualToString:@"WIFI"]) {
            [properties setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
        } else {
            [properties setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
        }
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_CARRIER] forKey:SA_EVENT_COMMON_PROPERTY_CARRIER];
        if ([self isFirstDay]) {
            [properties setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
        } else {
            [properties setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
        }
        [properties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_DEVICE_ID] forKey:SA_EVENT_COMMON_PROPERTY_DEVICE_ID];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    return [properties copy];
}

- (void)setServerUrl:(NSString *)serverUrl {
    self.network.serverURL = [NSURL URLWithString:serverUrl];
}

- (void)configServerURLWithDebugMode:(SensorsAnalyticsDebugMode)debugMode showDebugModeWarning:(BOOL)isShow {
    _debugMode = debugMode;

    self.network.debugMode = debugMode;
    [self enableLog:debugMode != SensorsAnalyticsDebugOff];
    
    if (isShow) {
        NSString *logMessage = nil;
        logMessage = [NSString stringWithFormat:@"%@ initialized the instance of Sensors Analytics SDK with server url '%@', debugMode: '%@'",
                      self, self.configOptions.serverURL, [self debugModeToString:_debugMode]];
        //SDK 初始化时默认 debugMode 为 DebugOff，SALog 不会打印日志
        //为了解决不能打印的问题，此处直接使用实例方法。其他地方不推荐使用此方法
        NSLog(@"%@", logMessage);
        
        //打开debug模式，弹出提示
#ifndef SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING
        if (_debugMode != SensorsAnalyticsDebugOff) {
            NSString *alertMessage = nil;
            if (_debugMode == SensorsAnalyticsDebugOnly) {
                alertMessage = @"现在您打开了'DEBUG_ONLY'模式，此模式下只校验数据但不导入数据，数据出错时会以提示框的方式提示开发者，请上线前一定关闭。";
            } else if (_debugMode == SensorsAnalyticsDebugAndTrack) {
                alertMessage = @"现在您打开了'DEBUG_AND_TRACK'模式，此模式下会校验数据并且导入数据，数据出错时会以提示框的方式提示开发者，请上线前一定关闭。";
            }
            [self showDebugModeWarning:alertMessage withNoMoreButton:NO];
        }
#endif
        
    }
}

- (NSString *)debugModeToString:(SensorsAnalyticsDebugMode)debugMode {
    NSString *modeStr = nil;
    switch (debugMode) {
        case SensorsAnalyticsDebugOff:
            modeStr = @"DebugOff";
            break;
        case SensorsAnalyticsDebugAndTrack:
            modeStr = @"DebugAndTrack";
            break;
        case SensorsAnalyticsDebugOnly:
            modeStr = @"DebugOnly";
            break;
        default:
            modeStr = @"Unknown";
            break;
    }
    return modeStr;
}

- (void)showDebugModeWarning:(NSString *)message withNoMoreButton:(BOOL)showNoMore {
#ifndef SENSORS_ANALYTICS_DISABLE_DEBUG_WARNING
    if (_debugMode == SensorsAnalyticsDebugOff) {
        return;
    }

    if (!_showDebugAlertView) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (self->_debugAlertViewHasShownNumber >= 3) {
                return;
            }
            self->_debugAlertViewHasShownNumber += 1;
            NSString *alertTitle = @"SensorsData 重要提示";
            SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:message preferredStyle:SAAlertControllerStyleAlert];
            [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleCancel handler:^(SAAlertAction * _Nonnull action) {
                self->_debugAlertViewHasShownNumber -= 1;
            }];
            if (showNoMore) {
                [alertController addActionWithTitle:@"不再显示" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
                    self->_showDebugAlertView = NO;
                }];
            }
            [alertController show];
        } @catch (NSException *exception) {
        } @finally {
        }
    });
#endif
}

- (void)showDebugModeAlertWithParams:(NSDictionary<NSString *, id> *)params {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            
            dispatch_block_t alterViewBlock = ^{
                
                NSString *alterViewMessage = @"";
                if (self->_debugMode == SensorsAnalyticsDebugAndTrack) {
                    alterViewMessage = @"开启调试模式，校验数据，并将数据导入神策分析中；\n关闭 App 进程后，将自动关闭调试模式。";
                } else if (self -> _debugMode == SensorsAnalyticsDebugOnly) {
                    alterViewMessage = @"开启调试模式，校验数据，但不进行数据导入；\n关闭 App 进程后，将自动关闭调试模式。";
                } else {
                    alterViewMessage = @"已关闭调试模式，重新扫描二维码开启";
                }
                SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"" message:alterViewMessage preferredStyle:SAAlertControllerStyleAlert];
                [alertController addActionWithTitle:@"确定" style:SAAlertActionStyleCancel handler:nil];
                [alertController show];
            };
            
            NSString *alertTitle = @"SDK 调试模式选择";
            NSString *alertMessage = @"";
            if (self->_debugMode == SensorsAnalyticsDebugAndTrack) {
                alertMessage = @"当前为 调试模式（导入数据）";
            } else if (self->_debugMode == SensorsAnalyticsDebugOnly) {
                alertMessage = @"当前为 调试模式（不导入数据）";
            } else {
                alertMessage = @"调试模式已关闭";
            }
            SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];
            void(^handler)(SensorsAnalyticsDebugMode) = ^(SensorsAnalyticsDebugMode debugMode) {
                [self configServerURLWithDebugMode:debugMode showDebugModeWarning:NO];
                alterViewBlock();
                [self.network debugModeCallbackWithDistinctId:self.distinctId params:params];
            };
            [alertController addActionWithTitle:@"开启调试模式（导入数据）" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
                handler(SensorsAnalyticsDebugAndTrack);
            }];
            [alertController addActionWithTitle:@"开启调试模式（不导入数据）" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
                handler(SensorsAnalyticsDebugOnly);
            }];
            [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:nil];
            [alertController show];
        } @catch (NSException *exception) {
        } @finally {
        }
    });
}

- (BOOL)isFirstDay {
    NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];

    return [[self firstDay] isEqualToString:current];
}

- (void)setFlushNetworkPolicy:(SensorsAnalyticsNetworkType)networkType {
    @synchronized (self) {
        _networkTypePolicy = networkType;
    }
}

- (SensorsAnalyticsNetworkType)toNetworkType:(NSString *)networkType {
    if ([@"NULL" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeNONE;
    } else if ([@"WIFI" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeWIFI;
    } else if ([@"2G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType2G;
    }   else if ([@"3G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType3G;
    }   else if ([@"4G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType4G;
    } else if ([@"UNKNOWN" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType4G;
    }
    return SensorsAnalyticsNetworkTypeNONE;
}

- (UIViewController *)currentViewController {
    return [SAAutoTrackUtils currentViewController];
}

- (void)setMaxCacheSize:(UInt64)maxCacheSize {
    @synchronized(self) {
        //防止设置的值太小导致事件丢失
        UInt64 temMaxCacheSize = maxCacheSize > 10000 ? maxCacheSize : 10000;
        self.configOptions.maxCacheSize = (NSInteger)temMaxCacheSize;
    };
}

- (UInt64)getMaxCacheSize {
    @synchronized(self) {
        return (UInt64)self.configOptions.maxCacheSize;
    };
}

- (NSMutableDictionary *)webViewJavascriptBridgeCallbackInfo {
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"iOS" forKey:SA_EVENT_TYPE];
    if (self.loginId != nil) {
        [libProperties setValue:self.loginId forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else{
        [libProperties setValue:self.anonymousId forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}

- (void)login:(NSString *)loginId {
    [self login:loginId withProperties:nil];
}

- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties {
    if (loginId == nil || loginId.length == 0) {
        SALogError(@"%@ cannot login blank login_id: %@", self, loginId);
        return;
    }
    if (loginId.length > 255) {
        SALogError(@"%@ max length of login_id is 255, login_id: %@", self, loginId);
        return;
    }
    
    dispatch_async(self.serialQueue, ^{
        if (![loginId isEqualToString:self.loginId]) {
            self.loginId = loginId;
            [self archiveLoginId];
            if (![loginId isEqualToString:self.anonymousId]) {
                self.originalId = self.anonymousId;
                NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
                // 添加来源渠道信息
                [eventProperties addEntriesFromDictionary:[self.linkHandler latestUtmProperties]];
                [eventProperties addEntriesFromDictionary:properties];
                [self track:SA_EVENT_NAME_APP_SIGN_UP withProperties:eventProperties withType:@"track_signup"];
                [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGIN_NOTIFICATION object:nil];
            }
        }
    });
}

- (void)logout {
    dispatch_async(self.serialQueue, ^{
        self.loginId = nil;
        [self archiveLoginId];
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_LOGOUT_NOTIFICATION object:nil];
    });
}

- (NSString *)anonymousId {
    if (!_anonymousId) {
        [self resetAnonymousId];
    }
    return _anonymousId;
}

-(NSString *)distinctId {
    NSString *distinctId = self.loginId;
    if (distinctId.length == 0) {
        distinctId = self.anonymousId;
    }
    return distinctId;
}

- (void)resetAnonymousId {
    _anonymousId = [self.class getUniqueHardwareId];
    [self archiveAnonymousId];
    if (!self.loginId) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_RESETANONYMOUSID_NOTIFICATION object:nil];
    }
}

- (void)trackAppCrash {
    _configOptions.enableTrackAppCrash = YES;
    // Install uncaught exception handlers first
    [[SensorsAnalyticsExceptionHandler sharedHandler] addSensorsAnalyticsInstance:self];
}

- (void)enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType {
    if (self.configOptions.autoTrackEventType != eventType) {
        self.configOptions.autoTrackEventType = eventType;
        
        [self _enableAutoTrack];
    }
}

- (void)autoTrackAppStart {
    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SA_HAS_LAUNCHED_ONCE]) {
        isFirstStart = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SA_HAS_LAUNCHED_ONCE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart]) {
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *eventName = [self isLaunchedPassively] ? SA_EVENT_NAME_APP_START_PASSIVELY : SA_EVENT_NAME_APP_START;
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND] = @(self->_appRelaunched);
        properties[SA_EVENT_PROPERTY_APP_FIRST_START] = @(isFirstStart);
        //添加 deeplink 相关渠道信息，可能不存在
        [properties addEntriesFromDictionary:[_linkHandler utmProperties]];

        [self track:eventName withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    });
}

- (void)startAppEndTimer {
    if ([self isLaunchedPassively]) {
        return;
    }

    // 启动 AppEnd 事件计时器
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self trackTimerStart:SA_EVENT_NAME_APP_END];
    });
}

- (BOOL)isAutoTrackEnabled {
    if (sharedInstance.remoteConfig.disableSDK) {
        return NO;
    }
    if (self.remoteConfig.autoTrackMode != kSAAutoTrackModeDefault) {
        if (self.remoteConfig.autoTrackMode == kSAAutoTrackModeDisabledAll) {
            return NO;
        } else {
            return YES;
        }
    }
    return (self.configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone);
}

- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType {

    if (sharedInstance.remoteConfig.disableSDK) {
        return YES;
    }
    if (self.remoteConfig.autoTrackMode != kSAAutoTrackModeDefault) {
        if (self.remoteConfig.autoTrackMode == kSAAutoTrackModeDisabledAll) {
            return YES;
        } else {
            return !(self.remoteConfig.autoTrackMode & eventType);
        }
    }
    return !(self.configOptions.autoTrackEventType & eventType);
}

- (void)ignoreViewType:(Class)aClass {
    [_ignoredViewTypeList addObject:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    for (Class obj in _ignoredViewTypeList) {
        if ([aClass isSubclassOfClass:obj]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    if (viewController == nil) {
        return NO;
    }
    NSString *screenName = NSStringFromClass([viewController class]);
    if (_ignoredViewControllers.count > 0 && [_ignoredViewControllers containsObject:screenName]) {
        return YES;
    }
    
    return NO;
}

- (void)showDebugInfoView:(BOOL)show {
    _showDebugAlertView = show;
}

- (BOOL)flushByType:(NSString *)type flushSize:(int)flushSize {
    // 1、获取前 n 条数据
    NSArray *recordArray = [self.messageQueue getFirstRecords:flushSize withType:@"POST"];
    if (recordArray == nil) {
        SALogError(@"Failed to get records from SQLite.");
        return NO;
    }
    // 2、上传获取到的记录。如果数据上传完成，结束递归
    if (recordArray.count == 0 || ![self.network flushEvents:recordArray]) {
        return NO;
    }
    // 3、删除已上传的记录。删除失败，结束递归
    if (![self.messageQueue removeFirstRecords:recordArray.count withType:@"POST"]) {
        SALogError(@"Failed to remove records from SQLite.");
        return NO;
    }
    // 4、继续上传剩余数据
    [self flushByType:type flushSize:flushSize];
    return YES;
}

- (void)_flush:(BOOL) vacuumAfterFlushing {
    if (![self.network isValidServerURL]) {
        return;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
    if (!([self toNetworkType:networkType] & _networkTypePolicy)) {
        return;
    }

    BOOL uploadedEvents = [self flushByType:@"Post" flushSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1)];

    if (vacuumAfterFlushing) {
        if (![self.messageQueue vacuum]) {
            SALogError(@"failed to VACUUM SQLite.");
        }
    }
    if (uploadedEvents) {
        SALogDebug(@"events flushed.");
    }
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self _flush:NO];
    });
}

- (void)deleteAll {
    // 新增线程保护
    dispatch_async(self.serialQueue, ^{
        [self.messageQueue deleteAll];
    });
}

#pragma mark - HandleURL
- (BOOL)canHandleURL:(NSURL *)url {
   return [[SAAuxiliaryToolManager sharedInstance] canHandleURL:url] || [_linkHandler canHandleURL:url];
}

- (BOOL)handleAutoTrackURL:(NSURL *)URL{
    if (URL == nil) {
        return NO;
    }
    NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
    BOOL isWifi = NO;
    if ([networkType isEqualToString:@"WIFI"]) {
        isWifi = YES;
    }
    return [[SAAuxiliaryToolManager sharedInstance] handleURL:URL isWifi:isWifi];
}


- (BOOL)handleSchemeUrl:(NSURL *)url {
    @try {
        if (!url) {
            return NO;
        }
        
        if ([[SAAuxiliaryToolManager sharedInstance] isVisualizedAutoTrackURL:url] || [[SAAuxiliaryToolManager sharedInstance] isHeatMapURL:url]) {
            //点击图 & 可视化全埋点
            return [self handleAutoTrackURL:url];
        } else if ([[SAAuxiliaryToolManager sharedInstance] isDebugModeURL:url]) {//动态 debug 配置
            // url query 解析
            NSMutableDictionary *paramDic = [[SAURLUtils queryItemsWithURL:url] mutableCopy];

            //如果没传 info_id，视为伪造二维码，不做处理
            if (paramDic.allKeys.count &&  [paramDic.allKeys containsObject:@"info_id"]) {
                [self showDebugModeAlertWithParams:paramDic];
                return YES;
            } else {
                return NO;
            }
        } else if ([_linkHandler canHandleURL:url]) {
            [_linkHandler handleDeepLink:url];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return NO;
}

#pragma mark - VisualizedAutoTrack
- (BOOL)isVisualizedAutoTrackEnabled {
    return self.configOptions.enableVisualizedAutoTrack;
}

- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    if (![controllers isKindOfClass:[NSArray class]] || controllers.count == 0) {
        return;
    }
    [_visualizedAutoTrackViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }

    if (_visualizedAutoTrackViewControllers.count == 0 && self.configOptions.enableVisualizedAutoTrack) {
        return YES;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [_visualizedAutoTrackViewControllers containsObject:screenName];
}

#pragma mark - Heat Map
- (BOOL)isHeatMapEnabled {
    return self.configOptions.enableHeatMap;
}

- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers {
    if (![controllers isKindOfClass:[NSArray class]] || controllers.count == 0) {
        return;
    }
    [_heatMapViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isHeatMapViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }

    if (_heatMapViewControllers.count == 0 && self.configOptions.enableHeatMap) {
        return YES;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [_heatMapViewControllers containsObject:screenName];
}

#pragma mark - Item 操作
- (void)itemSetWithType:(NSString *)itemType itemId:(NSString *)itemId properties:(nullable NSDictionary <NSString *, id> *)propertyDict {
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    itemDict[SA_EVENT_TYPE] = SA_EVENT_ITEM_SET;
    itemDict[SA_EVENT_ITEM_TYPE] = itemType;
    itemDict[SA_EVENT_ITEM_ID] = itemId;

    dispatch_async(self.serialQueue, ^{
        [self trackItems:itemDict properties:propertyDict];
    });
}

- (void)itemDeleteWithType:(NSString *)itemType itemId:(NSString *)itemId {
    NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] init];
    itemDict[SA_EVENT_TYPE] = SA_EVENT_ITEM_DELETE;
    itemDict[SA_EVENT_ITEM_TYPE] = itemType;
    itemDict[SA_EVENT_ITEM_ID] = itemId;
    
    dispatch_async(self.serialQueue, ^{
        [self trackItems:itemDict properties:nil];
    });
}

- (void)trackItems:(nullable NSDictionary <NSString *, id> *)itemDict properties:(nullable NSDictionary <NSString *, id> *)propertyDict {
    //item_type 必须为合法变量名
    NSString *itemType = itemDict[SA_EVENT_ITEM_TYPE];
    if (itemType.length == 0 || ![self isValidName:itemType]) {
        NSString *errMsg = [NSString stringWithFormat:@"item_type name[%@] not valid", itemType];
        SALogError(@"%@", errMsg);
        if (_debugMode != SensorsAnalyticsDebugOff) {
            [self showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        return;
    }

    NSString *itemId = itemDict[SA_EVENT_ITEM_ID];
    if (itemId.length == 0 || itemId.length > 255) {
        SALogError(@"%@ max length of item_id is 255, item_id: %@", self, itemId);
        return;
    }

    // 校验 properties
    NSString *type = itemDict[SA_EVENT_TYPE];
    if (![self assertPropertyTypes:&propertyDict withEventType:type]) {
        SALogError(@"%@ failed to item properties", self);
        return;
    }

    NSMutableDictionary *itemProperties = [NSMutableDictionary dictionaryWithDictionary:itemDict];
    if (propertyDict.count > 0) {
        itemProperties[SA_EVENT_PROPERTIES] = propertyDict;
    }

    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"code" forKey:SA_EVENT_COMMON_PROPERTY_LIB_METHOD];
    [libProperties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB] forKey:SA_EVENT_COMMON_PROPERTY_LIB];
    [libProperties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION] forKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION];
    NSString *app_version = [_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
    if (app_version) {
        [libProperties setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
    }

    if (libProperties.count > 0) {
        itemProperties[SA_EVENT_LIB] = libProperties;
    }

    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    itemProperties[SA_EVENT_TIME] = timeStamp;

    SALogDebug(@"\n【track event】:\n%@", itemProperties);

    [self enqueueWithType:@"Post" andEvent:itemProperties];
}
#pragma mark - track event

- (BOOL)isValidName:(NSString *)name {
    @try {
        // 保留字段通过字符串直接比较，效率更高
        NSSet *reservedProperties = sensorsdata_reserved_properties();
        for (NSString *reservedProperty in reservedProperties) {
            if ([reservedProperty caseInsensitiveCompare:name] == NSOrderedSame) {
                return NO;
            }
        }
        // 属性名通过正则表达式匹配，比使用谓词效率更高
        NSRange range = NSMakeRange(0, name.length);
        return ([self.propertiesRegex numberOfMatchesInString:name options:0 range:range] > 0);
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
        return NO;
    }
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
    if (![self assertPropertyTypes:&originProperties withEventType:type]) {
        SALogError(@"%@ failed to track event.", self);
        return nil;
    }
    return event;
}

- (void)enqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    [self.messageQueue addObject:e withType:@"Post"];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withType:(NSString *)type {
    if (self.remoteConfig.disableSDK) {
        return;
    }
    propertieDict = [propertieDict copy];
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"autoTrack" forKey:SA_EVENT_COMMON_PROPERTY_LIB_METHOD];

    // 对于type是track数据，它们的event名称是有意义的
    if ([type isEqualToString:@"track"] || [type isEqualToString:@"codeTrack"]) {
        if (event == nil || [event length] == 0) {
            NSString *errMsg = @"SensorsAnalytics track called with empty event parameter";
            SALogError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return;
        }
        if (![self isValidName:event]) {
            NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
            SALogError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return;
        }

        if ([type isEqualToString:@"codeTrack"]) {
            [libProperties setValue:@"code" forKey:SA_EVENT_COMMON_PROPERTY_LIB_METHOD];
            type = @"track";
        }
    }

    if (propertieDict) {
        if (![self assertPropertyTypes:&propertieDict withEventType:type]) {
            SALogError(@"%@ failed to track event.", self);
            return;
        }
    }
    [libProperties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB] forKey:SA_EVENT_COMMON_PROPERTY_LIB];
    [libProperties setValue:[_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION] forKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION];
    id app_version = [_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
    if (app_version) {
        [libProperties setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
    }

    NSString *lib_detail = nil;
    if ([self isAutoTrackEnabled] && propertieDict) {
        //不考虑 $AppClick 或者 $AppViewScreen 的计时采集，所以这里的 event 不会出现是 trackTimerStart 返回值的情况
        if ([event isEqualToString:SA_EVENT_NAME_APP_CLICK]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
                lib_detail = [NSString stringWithFormat:@"%@######", [propertieDict objectForKey:SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        } else if ([event isEqualToString:SA_EVENT_NAME_APP_VIEW_SCREEN]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppViewScreen] == NO) {
                lib_detail = [NSString stringWithFormat:@"%@######", [propertieDict objectForKey:SA_EVENT_PROPERTY_SCREEN_NAME] ?: @""];
            }
        }
    }

    if (lib_detail) {
        [libProperties setValue:lib_detail forKey:SA_EVENT_COMMON_PROPERTY_LIB_DETAIL];
    }
    __block NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties?self.dynamicSuperProperties():nil;
    UInt64 currentSystemUpTime = [[self class] getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        //根据当前 event 解析计时操作时加工前的原始 eventName，若当前 event 不是 trackTimerStart 计时操作后返回的字符串，event 和 eventName 一致
        NSString *eventName = [self.trackTimer eventNameFromEventId:event];

        //获取用户自定义的动态公共属性
        if (dynamicSuperPropertiesDict && [dynamicSuperPropertiesDict isKindOfClass:NSDictionary.class] == NO) {
            SALogDebug(@"dynamicSuperProperties  returned: %@  is not an NSDictionary Obj.", dynamicSuperPropertiesDict);
            dynamicSuperPropertiesDict = nil;
        } else {
            if ([self assertPropertyTypes:&dynamicSuperPropertiesDict withEventType:@"register_super_properties"] == NO) {
                dynamicSuperPropertiesDict = nil;
            }
        }
        //去重
        [self unregisterSameLetterSuperProperties:dynamicSuperPropertiesDict];

        NSNumber *timeStamp = @([[self class] getCurrentTime]);
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        if ([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
            // track / track_signup 类型的请求，还是要加上各种公共property
            // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties,dynamicSuperPropertiesDict,propertieDict
            [p addEntriesFromDictionary:self->_automaticProperties];
            [p addEntriesFromDictionary:self->_superProperties];
            [p addEntriesFromDictionary:dynamicSuperPropertiesDict];

            //update lib $app_version from super properties
            id app_version = [self->_superProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            if (app_version) {
                [libProperties setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            }

            // 每次 track 时手机网络状态
            NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
            [p setObject:networkType forKey:SA_EVENT_COMMON_PROPERTY_NETWORK_TYPE];
            if ([networkType isEqualToString:@"WIFI"]) {
                [p setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
            } else {
                [p setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
            }

            //根据 event 获取事件时长，如返回为 Nil 表示此事件没有相应事件时长，不设置 event_duration 属性
            //为了保证事件时长准确性，当前开机时间需要在 serialQueue 队列外获取，再在此处传入方法内进行计算
            NSNumber *eventDuration = [self.trackTimer eventDurationFromEventId:event currentSysUpTime:currentSystemUpTime];
            if (eventDuration) {
                p[@"event_duration"] = eventDuration;
            }
        }

        NSString *project = nil;
        NSString *token = nil;
        if (propertieDict) {
            NSArray *keys = propertieDict.allKeys;
            for (id key in keys) {
                NSObject *obj = propertieDict[key];
                if ([key isEqualToString:SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT]) {
                    project = (NSString *)obj;
                } else if ([key isEqualToString:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN]) {
                    token = (NSString *)obj;
                } else if ([key isEqualToString:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME]) {
                    if ([obj isKindOfClass:NSDate.class]) {
                        NSDate *customTime = (NSDate *)obj;
                        NSInteger customTimeInt = [customTime timeIntervalSince1970] * 1000;
                        if (customTimeInt >= SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME_INT) {
                            timeStamp = @(customTimeInt);
                        } else {
                            SALogError(@"$time error %ld，Please check the value", customTimeInt);
                        }
                    } else {
                        SALogError(@"$time '%@' invalid，Please check the value", obj);
                    }
                } else {
                    if ([obj isKindOfClass:[NSDate class]]) {
                        // 序列化所有 NSDate 类型
                        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd HH:mm:ss.SSS"];
                        NSString *dateStr = [dateFormatter stringFromDate:(NSDate *)obj];
                        [p setObject:dateStr forKey:key];
                    } else {
                        [p setObject:obj forKey:key];
                    }
                }
            }
        }

        NSMutableDictionary *e;
        NSString *bestId = self.distinctId;

        if ([type isEqualToString:@"track_signup"]) {
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 eventName, SA_EVENT_NAME,
                 [NSDictionary dictionaryWithDictionary:p], SA_EVENT_PROPERTIES,
                 bestId, SA_EVENT_DISTINCT_ID,
                 self.originalId, @"original_id",
                 timeStamp, SA_EVENT_TIME,
                 type, SA_EVENT_TYPE,
                 libProperties, SA_EVENT_LIB,
                 @(arc4random()), SA_EVENT_TRACK_ID,
                 nil];
        } else if([type isEqualToString:@"track"]) {
            //  是否首日访问
            if ([self isFirstDay]) {
                [p setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
            } else {
                [p setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
            }

            @try {
                if ([self isLaunchedPassively]) {
                    [p setObject:@"background" forKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_APP_STATE];
                }
            } @catch (NSException *e) {
                SALogError(@"%@: %@", self, e);
            }

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            @try {
                //采集设备方向
                if (self.deviceOrientationConfig.enableTrackScreenOrientation && self.deviceOrientationConfig.deviceOrientation.length) {
                    [p setObject:self.deviceOrientationConfig.deviceOrientation forKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_SCREEN_ORIENTATION];
                }
            } @catch (NSException *e) {
                SALogError(@"%@: %@", self, e);
            }
#endif

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
            @try {
                //采集地理位置信息
                if (self.locationConfig.enableGPSLocation) {
                    if (CLLocationCoordinate2DIsValid(self.locationConfig.coordinate)) {
                        NSInteger latitude = self.locationConfig.coordinate.latitude * pow(10, 6);
                        NSInteger longitude = self.locationConfig.coordinate.longitude * pow(10, 6);
                        [p setObject:@(latitude) forKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_LATITUDE];
                        [p setObject:@(longitude) forKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_LONGITUDE];
                    }
                }
            } @catch (NSException *e) {
                SALogError(@"%@: %@", self, e);
            }
#endif
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 eventName, SA_EVENT_NAME,
                 [NSDictionary dictionaryWithDictionary:p], SA_EVENT_PROPERTIES,
                 bestId, SA_EVENT_DISTINCT_ID,
                 timeStamp, SA_EVENT_TIME,
                 type, SA_EVENT_TYPE,
                 libProperties, SA_EVENT_LIB,
                 @(arc4random()), SA_EVENT_TRACK_ID,
                 nil];
        } else {
            // 此时应该都是对Profile的操作
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 [NSDictionary dictionaryWithDictionary:p], SA_EVENT_PROPERTIES,
                 bestId, SA_EVENT_DISTINCT_ID,
                 timeStamp, SA_EVENT_TIME,
                 type, SA_EVENT_TYPE,
                 libProperties, SA_EVENT_LIB,
                 @(arc4random()), SA_EVENT_TRACK_ID,
                 nil];
        }

        if (project) {
            [e setObject:project forKey:SA_EVENT_PROJECT];
        }
        if (token) {
            [e setObject:token forKey:SA_EVENT_TOKEN];
        }

        //修正 $device_id，防止用户修改
        NSDictionary *infoProperties = [e objectForKey:SA_EVENT_PROPERTIES];
        if (infoProperties && [infoProperties.allKeys containsObject:SA_EVENT_COMMON_PROPERTY_DEVICE_ID]) {
            NSDictionary *autoProperties = self.automaticProperties;
            if (autoProperties && [autoProperties.allKeys containsObject:SA_EVENT_COMMON_PROPERTY_DEVICE_ID]) {
                NSMutableDictionary *correctInfoProperties = [NSMutableDictionary dictionaryWithDictionary:infoProperties];
                correctInfoProperties[SA_EVENT_COMMON_PROPERTY_DEVICE_ID] = autoProperties[SA_EVENT_COMMON_PROPERTY_DEVICE_ID];
                [e setObject:correctInfoProperties forKey:SA_EVENT_PROPERTIES];
            }
        }

        NSDictionary *eventDic = [self willEnqueueWithType:type andEvent:e];
        if (!eventDic) {
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_EVENT_NOTIFICATION object:nil userInfo:eventDic];
        SALogDebug(@"\n【track event】:\n%@", eventDic);

        [self enqueueWithType:type andEvent:eventDic];

        if (self->_debugMode != SensorsAnalyticsDebugOff) {
            // 在DEBUG模式下，直接发送事件
            [self flush];
        } else {
            // 否则，在满足发送条件时，发送事件
            if ([type isEqualToString:@"track_signup"] || [[self messageQueue] count] >= self.configOptions.flushBulkSize) {
                [self flush];
            }
        }
    });
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil withTrackType:SensorsAnalyticsTrackTypeCode];;
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    [self track:event withProperties:propertieDict withTrackType:SensorsAnalyticsTrackTypeCode];
}

- (void)trackChannelEvent:(NSString *)event {
    [self trackChannelEvent:event properties:nil];
}

- (void)trackChannelEvent:(NSString *)event properties:(nullable NSDictionary *)propertyDict {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:propertyDict];
    // ua
    NSString *userAgent = [propertyDict objectForKey:SA_EVENT_PROPERTY_APP_USER_AGENT];

    dispatch_block_t trackChannelEventBlock = ^{
        // idfa
        NSString *idfa = [self getIDFA];
        if (idfa) {
            [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:SA_EVENT_PROPERTY_CHANNEL_INFO];
        } else {
            [properties setValue:@"" forKey:SA_EVENT_PROPERTY_CHANNEL_INFO];
        }

        if ([self.trackChannelEventNames containsObject:event]) {
            [properties setValue:@(NO) forKey:SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT];
        } else {
            [properties setValue:@(YES) forKey:SA_EVENT_PROPERTY_CHANNEL_CALLBACK_EVENT];
            [self.trackChannelEventNames addObject:event];
            dispatch_async(self.serialQueue, ^{
                [self archiveTrackChannelEventNames];
            });
        }

        [self track:event withProperties:properties withTrackType:SensorsAnalyticsTrackTypeCode];
    };

    if (userAgent.length == 0) {
        [self loadUserAgentWithCompletion:^(NSString *ua) {
            [properties setValue:ua forKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
            trackChannelEventBlock();
        }];
    } else {
        trackChannelEventBlock();
    }
}

- (void)track:(NSString *)event withTrackType:(SensorsAnalyticsTrackType)trackType {
    [self track:event withProperties:nil withTrackType:trackType];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withTrackType:(SensorsAnalyticsTrackType)trackType {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 添加 latest utms 属性，用户传入的属性优先级更高，最后添加到字典中
    [eventProperties addEntriesFromDictionary:[_linkHandler latestUtmProperties]];
    [eventProperties addEntriesFromDictionary:propertieDict];
    if (trackType == SensorsAnalyticsTrackTypeCode) {
        //事件校验，预置事件提醒
        if ([_presetEventNames containsObject:event]) {
            SALogError(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", event);
        };
        
        [self track:event withProperties:eventProperties withType:@"codeTrack"];
    } else {
        [self track:event withProperties:eventProperties withType:@"track"];
    }
}

- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    [_network setCookie:cookie isEncoded:encode];
}

- (NSString *)getCookieWithDecode:(BOOL)decode {
    return [_network cookieWithDecoded:decode];
}

- (BOOL)checkEventName:(NSString *)eventName {
    if ([self isValidName:eventName]) {
        return YES;
    }
    NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", eventName];
    SALogError(@"%@", errMsg);
    if (_debugMode != SensorsAnalyticsDebugOff) {
        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
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
    [self track:event withTrackType:SensorsAnalyticsTrackTypeAuto];
}

- (void)trackTimerEnd:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self track:event withProperties:propertyDict withTrackType:SensorsAnalyticsTrackTypeAuto];
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

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer clearAllEventTimers];
    });
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {
    NSString *userDefaultsKey = disableCallback ? SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK : SA_HAS_TRACK_INSTALLATION;
    BOOL hasTrackInstallation = [[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey];
    if (hasTrackInstallation) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
#ifndef SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN
    hasTrackInstallation = disableCallback ? [SAKeyChainItemWrapper hasTrackInstallationWithDisableCallback] : [SAKeyChainItemWrapper hasTrackInstallation];
    if (hasTrackInstallation) {
        return;
    }
    if (disableCallback) {
        [SAKeyChainItemWrapper markHasTrackInstallationWithDisableCallback];
    } else {
        [SAKeyChainItemWrapper markHasTrackInstallation];
    }
#endif
#endif

    if (!hasTrackInstallation) {

        // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        NSString *idfa = [self getIDFA];
        if (idfa != nil) {
            [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];
        } else {
            [properties setValue:@"" forKey:SA_EVENT_PROPERTY_APP_INSTALL_SOURCE];
        }

        if (disableCallback) {
            [properties setValue:@YES forKey:SA_EVENT_PROPERTY_APP_INSTALL_DISABLE_CALLBACK];
        }

        __block NSString *userAgent = [propertyDict objectForKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
        dispatch_block_t trackInstallationBlock = ^{
            if (userAgent) {
                [properties setValue:userAgent forKey:SA_EVENT_PROPERTY_APP_USER_AGENT];
            }

            // 添加 deepLink 来源渠道信息
            // 来源渠道消息只需要添加到 event 事件中，这里使用一个新的字典来添加 latest_utms 参数
            NSMutableDictionary *eventProperties = [properties mutableCopy];
            [eventProperties addEntriesFromDictionary:[self.linkHandler latestUtmProperties]];
            [eventProperties addEntriesFromDictionary:propertyDict];

            // 先发送 track
            [self track:event withProperties:eventProperties withType:@"track"];

            // 再发送 profile_set_once
            // profile 事件不需要添加来源渠道信息，这里只追加用户传入的 propertyDict 和时间属性
            NSMutableDictionary *profileProperties = [properties mutableCopy];
            [profileProperties addEntriesFromDictionary:propertyDict];
            [profileProperties setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
            [self track:nil withProperties:profileProperties withType:SA_PROFILE_SET_ONCE];

            [self flush];
        };

        if (userAgent.length == 0) {
            [self loadUserAgentWithCompletion:^(NSString *ua) {
                userAgent = ua;
                trackInstallationBlock();
            }];
        } else {
            trackInstallationBlock();
        }
    }
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self trackInstallation:event withProperties:propertyDict disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event {
    [self trackInstallation:event withProperties:nil disableCallback:NO];
}

- (NSString  *)getIDFA {
    NSString *idfa = nil;
    @try {
//#if defined(SENSORS_ANALYTICS_IDFA)
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            NSString *temp = [uuid UUIDString];
            // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
            // 00000000-0000-0000-0000-000000000000
            if (temp && ![temp hasPrefix:@"00000000"]) {
                idfa = temp;
            }
        }
//#endif
        return idfa;
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
        return idfa;
    }
}

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [_ignoredViewControllers addObjectsFromArray:controllers];

    //去重
    NSSet *set = [NSSet setWithArray:_ignoredViewControllers];
    if (set != nil) {
        _ignoredViewControllers = [NSMutableArray arrayWithArray:[set allObjects]];
    } else {
        _ignoredViewControllers = [[NSMutableArray alloc] init];
    }
}

- (void)identify:(NSString *)anonymousId {
    if (anonymousId.length == 0) {
        SALogError(@"%@ cannot identify blank distinct id: %@", self, anonymousId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics distinct_id should not be nil or empty" userInfo:nil];
        return;
    }
    if (anonymousId.length > 255) {
        SALogError(@"%@ max length of distinct_id is 255, distinct_id: %@", self, anonymousId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics max length of distinct_id is 255" userInfo:nil];
    }
    
    dispatch_async(self.serialQueue, ^{
        // 先把之前的anonymousId设为originalId
        self.originalId = self.anonymousId;
        // 更新anonymousId
        self.anonymousId = anonymousId;
        [self archiveAnonymousId];
        if (!self.loginId) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SA_TRACK_IDENTIFY_NOTIFICATION object:nil];
        }
    });
}

- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

- (NSString *)libVersion {
    return VERSION;
}

- (BOOL)assertPropertyTypes:(NSDictionary **)propertiesAddress withEventType:(NSString *)eventType {
    NSDictionary *properties = *propertiesAddress;
    NSMutableDictionary *newProperties = nil;
    NSMutableArray *mutKeyArrayForValueIsNSNull = nil;
    for (id __unused k in properties) {
        // key 必须是NSString
        if (![k isKindOfClass: [NSString class]]) {
            NSString *errMsg = @"Property Key should by NSString";
            SALogError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }

        // key的名称必须符合要求
        if (![self isValidName: k]) {
            NSString *errMsg = [NSString stringWithFormat:@"property name[%@] is not valid", k];
            SALogError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }

        // value的类型检查
        id propertyValue = properties[k];
        if(![propertyValue isKindOfClass:[NSString class]] &&
           ![propertyValue isKindOfClass:[NSNumber class]] &&
           ![propertyValue isKindOfClass:[NSSet class]] &&
           ![propertyValue isKindOfClass:[NSArray class]] &&
           ![propertyValue isKindOfClass:[NSDate class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [propertyValue class], propertyValue];
            SALogError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }

            if ([propertyValue isKindOfClass:[NSNull class]]) {
                //NSNull 需要对数据做修复，remove 对应的 key
                if (!mutKeyArrayForValueIsNSNull) {
                    mutKeyArrayForValueIsNSNull = [NSMutableArray arrayWithObject:k];
                } else {
                    [mutKeyArrayForValueIsNSNull addObject:k];
                }
            } else {
                return NO;
            }
        }

        BOOL isDebugMode = _debugMode != SensorsAnalyticsDebugOff;
        NSString *(^verifyString)(NSString *, NSMutableDictionary **, id *) = ^NSString *(NSString *string, NSMutableDictionary **dic, id *objects) {
            // NSSet、NSArray 类型的属性中，每个元素必须是 NSString 类型
            if (![string isKindOfClass:[NSString class]]) {
                NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet、NSArray must be NSString. got: %@ %@", self, [string class], string];
                SALogError(@"%@", errMsg);
                if (isDebugMode) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return nil;
            }
            NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (length > SA_PROPERTY_LENGTH_LIMITATION) {
                //截取再拼接 $ 末尾，替换原数据
                NSMutableString *newString = [NSMutableString stringWithString:[SACommonUtility subByteString:string byteLength:SA_PROPERTY_LENGTH_LIMITATION - 1]];
                [newString appendString:@"$"];
                if (*dic == nil) {
                    *dic = [NSMutableDictionary dictionaryWithDictionary:properties];
                }

                if (*objects == nil) {
                    *objects = [propertyValue mutableCopy];
                }
                return newString;
            }
            return string;
        };
        if ([propertyValue isKindOfClass:[NSSet class]]) {
            id object;
            NSMutableSet *newSetObject = nil;
            NSEnumerator *enumerator = [propertyValue objectEnumerator];
            while (object = [enumerator nextObject]) {
                NSString *string = verifyString(object, &newProperties, &newSetObject);
                if (string == nil) {
                    return NO;
                } else if (string != object) {
                    [newSetObject removeObject:object];
                    [newSetObject addObject:string];
                }
            }
            if (newSetObject) {
                [newProperties setObject:newSetObject forKey:k];
            }
        } else if ([propertyValue isKindOfClass:[NSArray class]]) {
            NSMutableArray *newArray = nil;
            for (NSInteger index = 0; index < [propertyValue count]; index++) {
                id object = [propertyValue objectAtIndex:index];
                NSString *string = verifyString(object, &newProperties, &newArray);
                if (string == nil) {
                    return NO;
                } else if (string != object) {
                    [newArray replaceObjectAtIndex:index withObject:string];
                }
            }
            if (newArray) {
                [newProperties setObject:newArray forKey:k];
            }
        }

        // NSString 检查长度，但忽略部分属性
        if ([propertyValue isKindOfClass:[NSString class]]) {
            NSUInteger objLength = [((NSString *)propertyValue) lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSUInteger valueMaxLength = SA_PROPERTY_LENGTH_LIMITATION;
            if ([k isEqualToString:@"app_crashed_reason"]) {
                valueMaxLength = SA_PROPERTY_LENGTH_LIMITATION * 2;
            }
            if (objLength > valueMaxLength) {
                //截取再拼接 $ 末尾，替换原数据
                NSMutableString *newObject = [NSMutableString stringWithString:[SACommonUtility subByteString:propertyValue byteLength:valueMaxLength - 1]];
                [newObject appendString:@"$"];
                if (!newProperties) {
                    newProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
                }
                [newProperties setObject:newObject forKey:k];
            }
        }

        // profileIncrement的属性必须是NSNumber
        if ([eventType isEqualToString:SA_PROFILE_INCREMENT]) {
            if (![propertyValue isKindOfClass:[NSNumber class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [properties[k] class], propertyValue];
                SALogError(@"%@", errMsg);
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return NO;
            }
        }

        // profileAppend的属性必须是个NSSet、NSArray
        if ([eventType isEqualToString:SA_PROFILE_APPEND]) {
            if (![propertyValue isKindOfClass:[NSSet class]] && ![propertyValue isKindOfClass:[NSArray class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet、NSArray. got %@ %@", self, [propertyValue  class], propertyValue];
                SALogError(@"%@", errMsg);
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                }
                return NO;
            }
        }
    }
    //截取之后，修改原 properties
    if (newProperties) {
        *propertiesAddress = [NSDictionary dictionaryWithDictionary:newProperties];
    }

    if (mutKeyArrayForValueIsNSNull) {
        NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:*propertiesAddress];
        [mutDict removeObjectsForKeys:mutKeyArrayForValueIsNSNull];
        *propertiesAddress = [NSDictionary dictionaryWithDictionary:mutDict];
    }
    return YES;
}

- (NSDictionary *)collectAutomaticProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nil;

#ifdef __IPHONE_12_0
    if (@available(iOS 12.1, *)) {
        // 排序
        NSArray *carrierKeysArray = [telephonyInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
        carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
        if (!carrier.mobileNetworkCode) {
            carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
        }
    }
#endif
    if (!carrier) {
        carrier = telephonyInfo.subscriberCellularProvider;
    }
    if (carrier != nil) {
        NSString *networkCode = [carrier mobileNetworkCode];
        NSString *countryCode = [carrier mobileCountryCode];
        
        NSString *carrierName = nil;
        //中国运营商
        if (countryCode && [countryCode isEqualToString:CARRIER_CHINA_MCC]) {
            if (networkCode) {
                
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName= @"中国移动";
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName= @"中国联通";
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName= @"中国电信";
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName= @"中国卫通";
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName= @"中国铁通";
                }
            }
        } else if (countryCode && networkCode) { //国外运营商解析
            //加载当前 bundle
            NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
            //文件路径
            NSString *jsonPath = [sensorsBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
            NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
            if (jsonData) {
                NSDictionary *dicAllMcc =  [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
                if (dicAllMcc) {
                    NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                    carrierName = dicAllMcc[mccMncKey];
                }
            }
        }
        
        if (carrierName != nil) {
            [properties setValue:carrierName forKey:SA_EVENT_COMMON_PROPERTY_CARRIER];
        }
    }

    // Use setValue semantics to avoid adding keys where value can be nil.
    [properties setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];

#if !SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID
    [properties setValue:[[self class] getUniqueHardwareId] forKey:SA_EVENT_COMMON_PROPERTY_DEVICE_ID];
#endif

    UIDevice *device = [UIDevice currentDevice];
    _deviceModel = [self deviceModel];
    _osVersion = [device systemVersion];
    struct CGSize size = [UIScreen mainScreen].bounds.size;
    [properties addEntriesFromDictionary:@{
                                  SA_EVENT_COMMON_PROPERTY_LIB: @"iOS",
                                  SA_EVENT_COMMON_PROPERTY_LIB_VERSION: [self libVersion],
                                  SA_EVENT_COMMON_PROPERTY_MANUFACTURER: @"Apple",
                                  SA_EVENT_COMMON_PROPERTY_OS: @"iOS",
                                  SA_EVENT_COMMON_PROPERTY_OS_VERSION: _osVersion,
                                  SA_EVENT_COMMON_PROPERTY_MODEL: _deviceModel,
                                  SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT: @((NSInteger)size.height),
                                  SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH: @((NSInteger)size.width),
                                      }];
    return [properties copy];
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    propertyDict = [propertyDict copy];
    if (![self assertPropertyTypes:&propertyDict withEventType:@"register_super_properties"]) {
        SALogError(@"%@ failed to register super properties.", self);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self unregisterSameLetterSuperProperties:propertyDict];
        // 注意这里的顺序，发生冲突时是以propertyDict为准，所以它是后加入的
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self->_superProperties];
        [tmp addEntriesFromDictionary:propertyDict];
        self->_superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
}

- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties {
    dispatch_async(self.serialQueue, ^{
        self.dynamicSuperProperties = dynamicSuperProperties;
    });
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

///注销仅大小写不同的 SuperProperties
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict {
    dispatch_block_t block =^{
        NSArray *allNewKeys = [propertyDict.allKeys copy];
        //如果包含仅大小写不同的 key ,unregisterSuperProperty
        NSArray *superPropertyAllKeys = [self.superProperties.allKeys copy];
        NSMutableArray *unregisterPropertyKeys = [NSMutableArray array];
        for (NSString *newKey in allNewKeys) {
            [superPropertyAllKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *usedKey = (NSString *)obj;
                if ([usedKey caseInsensitiveCompare:newKey] == NSOrderedSame) { // 存在不区分大小写相同 key
                    [unregisterPropertyKeys addObject:usedKey];
                }
            }];
        }
        if (unregisterPropertyKeys.count > 0) {
            [self unregisterSuperPropertys:unregisterPropertyKeys];
        }
    };

    if (dispatch_get_specific(SensorsAnalyticsQueueTag)) {
        block();
    } else {
        dispatch_async(self.serialQueue, block);
    }
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self->_superProperties];
        if (tmp[property] != nil) {
            [tmp removeObjectForKey:property];
        }
        self->_superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
}

- (void)unregisterSuperPropertys:(NSArray<NSString *> *)propertys {
    dispatch_block_t block =  ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self->_superProperties];
        [tmp removeObjectsForKeys:propertys];
        self->_superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    };
    if (dispatch_get_specific(SensorsAnalyticsQueueTag)) {
        block();
    } else {
        dispatch_async(self.serialQueue, block);
    }
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        self->_superProperties = @{};
        [self archiveSuperProperties];
    });
}

- (NSDictionary *)currentSuperProperties {
    return [_superProperties copy];
}

#pragma mark - Local caches

- (void)unarchive {
    [self unarchiveAnonymousId];
    [self unarchiveLoginId];
    [self unarchiveSuperProperties];
    [self unarchiveFirstDay];
    [self unarchiveTrackChannelEvents];
}

- (void)unarchiveAnonymousId {
    NSString *archivedAnonymousId = (NSString *)[SAFileStore unarchiveWithFileName:SA_EVENT_DISTINCT_ID];

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    NSString *anonymousIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (anonymousIdInKeychain.length > 0) {
        self.anonymousId = anonymousIdInKeychain;
        if (![archivedAnonymousId isEqualToString:anonymousIdInKeychain]) {
            //保存 Archiver
            [SAFileStore archiveWithFileName:SA_EVENT_DISTINCT_ID value:self.anonymousId];
        }
    } else {
#endif
        if (archivedAnonymousId.length == 0) {
            self.anonymousId = [[self class] getUniqueHardwareId];
            [self archiveAnonymousId];
        } else {
            self.anonymousId = archivedAnonymousId;
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
            //保存 KeyChain
            [SAKeyChainItemWrapper saveUdid:self.anonymousId];
        }
#endif
    }
}

- (void)unarchiveLoginId {
    self.loginId = (NSString *)[SAFileStore unarchiveWithFileName:@"login_id"];
}

- (void)unarchiveFirstDay {
    self.firstDay = [SAFileStore unarchiveWithFileName:@"first_day"];
}

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = (NSDictionary *)[SAFileStore unarchiveWithFileName:@"super_properties"];
    _superProperties = archivedSuperProperties ? [archivedSuperProperties copy] : [NSDictionary dictionary];
}

- (void)unarchiveTrackChannelEvents {
    NSArray *trackChannelEvents = (NSArray *)[SAFileStore unarchiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO];
    [self.trackChannelEventNames addObjectsFromArray:trackChannelEvents];
}

- (void)archiveAnonymousId {
    [SAFileStore archiveWithFileName:SA_EVENT_DISTINCT_ID value:self.anonymousId];
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    [SAKeyChainItemWrapper saveUdid:self.anonymousId];
#endif
}

- (void)archiveLoginId {
    [SAFileStore archiveWithFileName:@"login_id" value:self.loginId];
}

- (void)archiveFirstDay {
    [SAFileStore archiveWithFileName:@"first_day" value:self.firstDay];
}

- (void)archiveSuperProperties {
    [SAFileStore archiveWithFileName:@"super_properties" value:self.superProperties];
}

- (void)archiveTrackChannelEventNames {
    [SAFileStore archiveWithFileName:SA_EVENT_PROPERTY_CHANNEL_INFO value:self.trackChannelEventNames];
}

#pragma mark - Network control

+ (NSString *)getNetWorkStates {
#ifdef SA_UT
    SADebug(@"In unit test, set NetWorkStates to wifi");
    return @"WIFI";
#endif
    NSString *network = @"NULL";
    @try {
        SAReachability *reachability = [SAReachability reachabilityForInternetConnection];
        SANetworkStatus status = [reachability currentReachabilityStatus];
        
        if (status == SAReachableViaWiFi) {
            network = @"WIFI";
        } else if (status == SAReachableViaWWAN) {
            static CTTelephonyNetworkInfo *netinfo = nil;
            NSString *currentRadioAccessTechnology = nil;
            
            if (!netinfo) {
                netinfo = [[CTTelephonyNetworkInfo alloc] init];
            }
#ifdef __IPHONE_12_0
            if (@available(iOS 12.1, *)) {
                currentRadioAccessTechnology = netinfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
            }
#endif
            //测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
            if (!currentRadioAccessTechnology) {
                currentRadioAccessTechnology = netinfo.currentRadioAccessTechnology;
            }
            
            if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                network = @"2G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
                network = @"2G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                network = @"4G";
            } else {
                network = @"UNKNOWN";
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return network;
}

- (void)startFlushTimer {
    if (self.remoteConfig.disableSDK || (self.timer && [self.timer isValid])) {
        return;
    }
    SALogDebug(@"starting flush timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
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
    return _referrerScreenUrl;
}

- (void)clearReferrerWhenAppEnd {
    _clearReferrerWhenAppEnd = YES;
}

- (NSDictionary *)getLastScreenTrackProperties {
    return _lastScreenTrackProperties;
}

- (SensorsAnalyticsDebugMode)debugMode {
    return _debugMode;
}

- (void)trackViewAppClick:(UIView *)view {
    [self trackViewAppClick:view withProperties:nil];
}

- (void)trackViewAppClick:(UIView *)view withProperties:(NSDictionary *)p {
    @try {
        if (view == nil) {
            return;
        }
        NSMutableDictionary *properties = [[NSMutableDictionary alloc]init];
        [properties addEntriesFromDictionary:[SAAutoTrackUtils propertiesWithAutoTrackObject:view isCodeTrack:YES]];
        [properties addEntriesFromDictionary:p];
        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

#pragma mark - UIApplication Events

- (void)setUpListeners {
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidFinishLaunching:)
                               name:UIApplicationDidFinishLaunchingNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminateNotification:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    
    [self _enableAutoTrack];
}

- (void)autoTrackViewScreen:(UIViewController *)controller {
    //过滤用户设置的不被AutoTrack的Controllers
    if (![self shouldTrackViewController:controller ofType:SensorsAnalyticsEventTypeAppViewScreen]) {
        return;
    }

    // 针对页面浏览，单独忽略：弹框
    if ([controller isKindOfClass:UIAlertController.class]) {
        return;
    }
    if (self.launchedPassively) {
        if (controller) {
            if (!self.launchedPassivelyControllers) {
                self.launchedPassivelyControllers = [NSMutableArray array];
            }
            [self.launchedPassivelyControllers addObject:controller];
        }
        return;
    }

    [self trackViewScreen:controller properties:nil autoTrack:YES];
}

- (void)trackViewScreen:(UIViewController *)controller {
    [self trackViewScreen:controller properties:nil];
}

- (void)trackViewScreen:(UIViewController *)controller properties:(nullable NSDictionary<NSString *, id> *)properties {
    [self trackViewScreen:controller properties:properties autoTrack:NO];
}

- (void)trackViewScreen:(UIViewController *)controller properties:(nullable NSDictionary<NSString *, id> *)properties autoTrack:(BOOL)autoTrack {
    if (!controller) {
        return;
    }

    if ([self isBlackListContainsViewController:controller]) {
        return;
    }

    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];

    NSDictionary *autoTrackProperties = [SAAutoTrackUtils propertiesWithViewController:controller];
    [eventProperties addEntriesFromDictionary:autoTrackProperties];

    if (autoTrack) {
        // App 通过 Deeplink 启动时第一个页面浏览事件会添加 utms 属性
        // 只需要处理全埋点的页面浏览事件
        [eventProperties addEntriesFromDictionary:[_linkHandler utmProperties]];
        [_linkHandler clearUtmProperties];
    }

    if ([controller conformsToProtocol:@protocol(SAAutoTracker)] && [controller respondsToSelector:@selector(getTrackProperties)]) {
        UIViewController<SAAutoTracker> *autoTrackerController = (UIViewController<SAAutoTracker> *)controller;
        NSDictionary *trackProperties = [autoTrackerController getTrackProperties];
        [eventProperties addEntriesFromDictionary:trackProperties];
    }
    _lastScreenTrackProperties = [eventProperties copy];

    NSString *currentScreenUrl;
    if ([controller conformsToProtocol:@protocol(SAScreenAutoTracker)] && [controller respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)controller;
        currentScreenUrl = [screenAutoTrackerController getScreenUrl];
    }
    currentScreenUrl = [currentScreenUrl isKindOfClass:NSString.class] ? currentScreenUrl : NSStringFromClass(controller.class);
    [eventProperties setValue:currentScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_URL];
    @synchronized(_referrerScreenUrl) {
        if (_referrerScreenUrl) {
            [eventProperties setValue:_referrerScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_REFERRER_URL];
        }
        _referrerScreenUrl = currentScreenUrl;
    }

    if (properties) {
        [eventProperties addEntriesFromDictionary:properties];
        NSMutableDictionary *tempProperties = [NSMutableDictionary dictionaryWithDictionary: _lastScreenTrackProperties];
        [tempProperties addEntriesFromDictionary:properties];
        _lastScreenTrackProperties = [tempProperties copy];
    }

    [self track:SA_EVENT_NAME_APP_VIEW_SCREEN withProperties:eventProperties withTrackType:SensorsAnalyticsTrackTypeAuto];
}

#ifdef SENSORS_ANALYTICS_REACT_NATIVE
static inline void sa_methodExchange(const char *className, const char *originalMethodName, const char *replacementMethodName, IMP imp) {
    @try {
        Class cls = objc_getClass(className);//得到指定类的类定义
        SEL oriSEL = sel_getUid(originalMethodName);//把originalMethodName注册到RunTime系统中
        Method oriMethod = class_getInstanceMethod(cls, oriSEL);//获取实例方法
        struct objc_method_description *desc = method_getDescription(oriMethod);//获得指定方法的描述
        if (desc->types) {
            SEL buSel = sel_registerName(replacementMethodName);//把replacementMethodName注册到RunTime系统中
            if (class_addMethod(cls, buSel, imp, desc->types)) {//通过运行时，把方法动态添加到类中
                Method buMethod  = class_getInstanceMethod(cls, buSel);//获取实例方法
                method_exchangeImplementations(oriMethod, buMethod);//交换方法
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
    }
}

static void sa_imp_setJSResponderBlockNativeResponder(id obj, SEL cmd, id reactTag, BOOL blockNativeResponder) {
    //先执行原来的方法
    SEL oriSel = sel_getUid("sda_setJSResponder:blockNativeResponder:");
    void (*setJSResponderWithBlockNativeResponder)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))[NSClassFromString(@"RCTUIManager") instanceMethodForSelector:oriSel];//函数指针
    setJSResponderWithBlockNativeResponder(obj, cmd, reactTag, blockNativeResponder);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            //关闭 AutoTrack
            if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
                return;
            }
            
            //忽略 $AppClick 事件
            if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
                return;
            }
            
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[NSClassFromString(@"RNView") class]]) {
                return;
            }
            
            if ([obj isKindOfClass:NSClassFromString(@"RCTUIManager")]) {
                SEL viewForReactTagSelector = NSSelectorFromString(@"viewForReactTag:");
                UIView *uiView = ((UIView* (*)(id, SEL, NSNumber *))[obj methodForSelector:viewForReactTagSelector])(obj, viewForReactTagSelector, reactTag);
                NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
                
                if ([uiView isKindOfClass:[NSClassFromString(@"RCTSwitch") class]] || [uiView isKindOfClass:[NSClassFromString(@"RCTScrollView") class]]) {
                    //好像跟 UISwitch 会重复
                    return;
                }
                
                [properties setValue:@"RNView" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];
                [properties setValue:[uiView.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
                
                UIViewController *viewController = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                if ([uiView respondsToSelector:NSSelectorFromString(@"reactViewController")]) {
                    viewController = [uiView performSelector:NSSelectorFromString(@"reactViewController")];
                }
#pragma clang diagnostic pop
                if (viewController) {
                    //获取 Controller 名称($screen_name)
                    NSString *screenName = NSStringFromClass([viewController class]);
                    [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];
                    
                    NSString *controllerTitle = viewController.navigationItem.title;
                    if (controllerTitle != nil) {
                        [properties setValue:viewController.navigationItem.title forKey:SA_EVENT_PROPERTY_TITLE];
                    }
                    
                    NSString *viewPath = [SAAutoTrackUtils viewSimilarPathForView:uiView atViewController:viewController shouldSimilarPath:NO];
                    if (viewPath) {
                        properties[SA_EVENT_PROPERTY_ELEMENT_PATH] = viewPath;
                    }
                }

                [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
        }
    });
}
#endif

- (void)_enableAutoTrack {
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW
    void (^unswizzleUITableViewAppClickBlock)(id, SEL, id) = ^(id obj, SEL sel, NSNumber* a) {
        UIViewController *controller = (UIViewController *)obj;
        if (!controller) {
            return;
        }
        
        Class klass = [controller class];
        if (!klass) {
            return;
        }
        
        NSString *screenName = NSStringFromClass(klass);
        
        //UITableView
    #ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW
        if ([controller respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            [SASwizzler unswizzleSelector:@selector(tableView:didSelectRowAtIndexPath:) onClass:klass named:[NSString stringWithFormat:@"%@_%@", screenName, @"UITableView_AutoTrack"]];
        }
    #endif
        
        //UICollectionView
    #ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW
        if ([controller respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
            [SASwizzler unswizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:) onClass:klass named:[NSString stringWithFormat:@"%@_%@", screenName, @"UICollectionView_AutoTrack"]];
        }
    #endif
    };
#endif
    
    // 监听所有 UIViewController 显示事件
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //$AppViewScreen
        [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sa_autotrack_viewDidAppear:) error:NULL];
        NSError *error = NULL;
        //$AppClick
        // Actions & Events
        [UIApplication sa_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                             withMethod:@selector(sa_sendAction:to:from:forEvent:)
                                  error:&error];
        if (error) {
            SALogError(@"Failed to swizzle sendAction:to:forEvent: on UIAppplication. Details: %@", error);
            error = NULL;
        }
    });
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW
    //$AppClick
    //UITableView、UICollectionView
    #if (!defined SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW) || (!defined SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW)
    [SASwizzler swizzleBoolSelector:@selector(viewWillDisappear:)
                            onClass:[UIViewController class]
                          withBlock:unswizzleUITableViewAppClickBlock
                              named:@"track_UITableView_UICollectionView_AppClick_viewWillDisappear"];
    #endif
#endif
    //UILabel
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_GESTURE
    static dispatch_once_t onceTokenGesture;
    dispatch_once(&onceTokenGesture, ^{

        NSError *error = NULL;
        //$AppClick
        [UITapGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                             withMethod:@selector(sa_addTarget:action:)
                                  error:&error];
        
        [UITapGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                                      withMethod:@selector(sa_initWithTarget:action:)
                                           error:&error];
        
        [UILongPressGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                                      withMethod:@selector(sa_addTarget:action:)
                                           error:&error];
        
        [UILongPressGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                                      withMethod:@selector(sa_initWithTarget:action:)
                                           error:&error];
        if (error) {
            SALogError(@"Failed to swizzle Target on UITapGestureRecognizer. Details: %@", error);
            error = NULL;
        }
    });
#endif
    
    //React Native
#ifdef SENSORS_ANALYTICS_REACT_NATIVE
    if (NSClassFromString(@"RCTUIManager")) {
        //        [SASwizzler swizzleSelector:NSSelectorFromString(@"setJSResponder:blockNativeResponder:") onClass:NSClassFromString(@"RCTUIManager") withBlock:reactNativeAutoTrackBlock named:@"track_React_Native_AppClick"];
        sa_methodExchange("RCTUIManager", "setJSResponder:blockNativeResponder:", "sda_setJSResponder:blockNativeResponder:", (IMP)sa_imp_setJSResponderBlockNativeResponder);
    }
#endif
}

- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion {
    @try {
        if (groupIdentifier == nil || [groupIdentifier isEqualToString:@""]) {
            return;
        }
        NSArray *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier:groupIdentifier];
        if (eventArray) {
            for (NSDictionary *dict in eventArray) {
                [[SensorsAnalyticsSDK sharedInstance] track:dict[SA_EVENT_NAME] withProperties:dict[SA_EVENT_PROPERTIES] withTrackType:SensorsAnalyticsTrackTypeAuto];
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

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    SALogDebug(@"%@ applicationDidFinishLaunchingNotification did become active", self);
    if (self.configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone) {
        //全埋点
        [self autoTrackAppStart];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    SALogDebug(@"%@ application will enter foreground", self);
    
    _appRelaunched = YES;
    self.launchedPassively = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SALogDebug(@"%@ application did become active", self);
    if (_appRelaunched) {
        //下次启动 App 的时候重新初始化
        NSDictionary *sdkConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_SDK_TRACK_CONFIG];
        [self setSDKWithRemoteConfigDict:sdkConfig];
    }
    if (self.remoteConfig.disableSDK) {
        //停止 SDK 的 flushtimer
        [self stopFlushTimer];
        
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        //停止采集设备方向信息
        [self.deviceOrientationManager stopDeviceMotionUpdates];
#endif
        
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        [self.locationManager stopUpdatingLocation];
#endif
        
        [self flush];//停止采集数据之后 flush 本地数据
    } else {
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
        if (self.deviceOrientationConfig.enableTrackScreenOrientation) {
            [self.deviceOrientationManager startDeviceMotionUpdates];
        }
#endif
        
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
        if (self.locationConfig.enableGPSLocation) {
            [self.locationManager startUpdatingLocation];
        }
#endif
    }
    
    if (_applicationWillResignActive) {
        _applicationWillResignActive = NO;
        return;
    }
    
    [self shouldRequestRemoteConfig];
    
    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SA_HAS_LAUNCHED_ONCE]) {
        isFirstStart = YES;
    }
    
    // 遍历 trackTimer
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer resumeAllEventTimers:currentSysUpTime];
    });

    if ([self isAutoTrackEnabled] && _appRelaunched) {
        // 追踪 AppStart 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
            NSMutableDictionary *properties = [NSMutableDictionary dictionary];
            properties[SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND] = @(_appRelaunched);
            properties[SA_EVENT_PROPERTY_APP_FIRST_START] = @(isFirstStart);
            [properties addEntriesFromDictionary:[_linkHandler utmProperties]];

            [self track:SA_EVENT_NAME_APP_START withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
        }
    }

    // 启动 AppEnd 事件计时器
    [self trackTimerStart:SA_EVENT_NAME_APP_END];

    //track 被动启动的页面浏览
    if (self.launchedPassivelyControllers) {
        [self.launchedPassivelyControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull controller, NSUInteger idx, BOOL * _Nonnull stop) {
            [self trackViewScreen:controller];
        }];
        self.launchedPassivelyControllers = nil;
    }
    
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    SALogDebug(@"%@ application will resign active", self);
    _applicationWillResignActive = YES;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SALogDebug(@"%@ application did enter background", self);

    // 清除本次启动解析的来源渠道信息
    [_linkHandler clearUtmProperties];

    _applicationWillResignActive = NO;
    
    [self stopFlushTimer];
    
    self.launchedPassively = NO;
    
    if (self.reqConfigBlock) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestFunctionalManagermentConfigWithCompletion:) object:self.reqConfigBlock];
        self.reqConfigBlock = nil;
    }
    
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
    [self.deviceOrientationManager stopDeviceMotionUpdates];
#endif
    
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
    [self.locationManager stopUpdatingLocation];
#endif

    UIApplication *application = UIApplication.sharedApplication;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^() {
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };

    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];

    // 遍历 trackTimer
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer pauseAllEventTimers:currentSysUpTime];
    });

    if ([self isAutoTrackEnabled]) {
        // 追踪 AppEnd 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
            if (_clearReferrerWhenAppEnd) {
                _referrerScreenUrl = nil;
            }
            [self track:SA_EVENT_NAME_APP_END withTrackType:SensorsAnalyticsTrackTypeAuto];
        }
    }

    if (self.flushBeforeEnterBackground) {
        dispatch_async(self.serialQueue, ^{
            [self _flush:YES];
            endBackgroundTask();
        });
    } else {
        dispatch_async(self.serialQueue, ^{
            endBackgroundTask();
        });
    }
}
- (void)applicationWillTerminateNotification:(NSNotification *)notification {
    SALogDebug(@"applicationWillTerminateNotification");
    dispatch_sync(self.serialQueue, ^{
    });
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

- (void)enableLog:(BOOL)enabelLog{
    [self enableLoggers:enabelLog];
}

- (void)enableLog {
    BOOL printLog = NO;
#if (defined SENSORS_ANALYTICS_ENABLE_LOG)
    printLog = YES;
#endif
    
    if ( [self debugMode] != SensorsAnalyticsDebugOff) {
        printLog = YES;
    }
    [self enableLog:printLog];
}

- (void)setSDKWithRemoteConfigDict:(NSDictionary *)configDict {
    @try {
        self.remoteConfig = [SASDKRemoteConfig configWithDict:configDict];
        if (self.remoteConfig.disableDebugMode) {
            [self configServerURLWithDebugMode:SensorsAnalyticsDebugOff  showDebugModeWarning:NO];
        }
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)setRemoteConfig:(SASDKRemoteConfig *)remoteConfig {
    dispatch_async(self.readWriteQueue, ^{
        self->_remoteConfig = remoteConfig;
    });
}

- (id)remoteConfig {
    __block SASDKRemoteConfig *remoteConfig = nil;
    dispatch_sync(self.readWriteQueue, ^{
        remoteConfig = self->_remoteConfig;
    });
    return remoteConfig;
}

- (void)shouldRequestRemoteConfig {
    
    //判断是否符合分散 remoteconfig 请求条件
    if (self.configOptions.disableRandomTimeRequestRemoteConfig || self.configOptions.maxRequestHourInterval < self.configOptions.minRequestHourInterval) {
        [self requestFunctionalManagermentConfig];
        SALogDebug(@"disableRandomTimeRequestRemoteConfig or minHourInterval and maxHourInterval error，Please check the value");
        return;
    }

    NSDictionary *requestTimeConfig = [[NSUserDefaults standardUserDefaults] objectForKey:SA_REQUEST_REMOTECONFIG_TIME];
    double randomTime = [[requestTimeConfig objectForKey:@"randomTime"] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:@"startDeviceTime"] doubleValue];
    //当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;

    dispatch_block_t createRandomTimeBlock = ^() {
        //转换成 秒 再取随机时间
        NSInteger durationSecond = (self.configOptions.maxRequestHourInterval - self.configOptions.minRequestHourInterval) * 60 * 60;
        NSInteger randomDurationTime = arc4random() % durationSecond;
        double createRandomTime = currentTime + (self.configOptions.minRequestHourInterval * 60 * 60) + randomDurationTime;

        NSDictionary *createRequestTimeConfig = @{@"randomTime": @(createRandomTime), @"startDeviceTime": @(currentTime) };
        [[NSUserDefaults standardUserDefaults] setObject:createRequestTimeConfig forKey:SA_REQUEST_REMOTECONFIG_TIME];
    };

    if (currentTime >= startDeviceTime && currentTime < randomTime) {
        return;
    }
    [self requestFunctionalManagermentConfig];
    createRandomTimeBlock();
}

- (void)requestFunctionalManagermentConfig {
    @try {
        [self requestFunctionalManagermentConfigDelay:0 index:0];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfigDelay:(NSTimeInterval) delay index:(NSUInteger) index {
    __weak typeof(self) weakself = self;
    void(^block)(BOOL success , NSDictionary *configDict) = ^(BOOL success , NSDictionary *configDict) {
        @try {
            if (success) {
                if(configDict != nil) {
                    //重新设置 config,处理 configDict 中的缺失参数
                    //用户没有配置远程控制选项，服务端默认返回{"disableSDK":false,"disableDebugMode":false}
                    NSString *v = [configDict valueForKey:@"v"];
                    NSNumber *disableSDK = [configDict valueForKeyPath:@"configs.disableSDK"];
                    NSNumber *disableDebugMode = [configDict valueForKeyPath:@"configs.disableDebugMode"];
                    NSNumber *autoTrackMode = [configDict valueForKeyPath:@"configs.autoTrackMode"];
                    //只在 disableSDK 由 false 变成 true 的时候发，主要是跟踪 SDK 关闭的情况。
                    if (disableSDK.boolValue == YES && weakself.remoteConfig.disableSDK == NO) {
                        [weakself track:@"DisableSensorsDataSDK" withProperties:@{} withTrackType:SensorsAnalyticsTrackTypeAuto];
                    }
                    //如果有字段缺失，需要设置为默认值
                    if (disableSDK == nil) {
                        disableSDK = [NSNumber numberWithBool:NO];
                    }
                    if (disableDebugMode == nil) {
                        disableDebugMode = [NSNumber numberWithBool:NO];
                    }
                    if (autoTrackMode == nil) {
                        autoTrackMode = [NSNumber numberWithInteger:-1];
                    }
                    NSDictionary *configToBeSet = nil;
                    if (v) {
                        configToBeSet = @{@"v": v, @"configs": @{@"disableSDK": disableSDK, @"disableDebugMode": disableDebugMode, @"autoTrackMode": autoTrackMode}};
                    } else {
                        configToBeSet = @{@"configs": @{@"disableSDK": disableSDK, @"disableDebugMode": disableDebugMode, @"autoTrackMode": autoTrackMode}};
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:configToBeSet forKey:SA_SDK_TRACK_CONFIG];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } else {
                if (index < weakself.pullSDKConfigurationRetryMaxCount - 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself requestFunctionalManagermentConfigDelay:30 index:index + 1];
                    });
                }
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
        }
    };
    @try {
        self.reqConfigBlock = block;
        [self performSelector:@selector(requestFunctionalManagermentConfigWithCompletion:) withObject:self.reqConfigBlock afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfigWithCompletion:(void(^)(BOOL success, NSDictionary*configDict )) completion{
    @try {
        NSString *networkTypeString = [SensorsAnalyticsSDK getNetWorkStates];
        SensorsAnalyticsNetworkType networkType = [self toNetworkType:networkTypeString];
        if (networkType == SensorsAnalyticsNetworkTypeNONE) {
            completion(NO, nil);
            return;
        }
        NSURL *url = [NSURL URLWithString:self.configOptions.remoteConfigURL];
        [self.network functionalManagermentConfigWithRemoteConfigURL:url version:self.remoteConfig.v completion:completion];
    } @catch (NSException *e) {
        SALogError(@"%@ error: %@", self, e);
    }
}

- (void)enableTrackScreenOrientation:(BOOL)enable {
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
    @try {
        self.deviceOrientationConfig.enableTrackScreenOrientation = enable;
        if (enable) {
            if (_deviceOrientationManager == nil) {
                _deviceOrientationManager = [[SADeviceOrientationManager alloc] init];
                __weak SensorsAnalyticsSDK *weakSelf = self;
                _deviceOrientationManager.deviceOrientationBlock = ^(NSString *deviceOrientation) {
                    __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
                    if (deviceOrientation) {
                        strongSelf.deviceOrientationConfig.deviceOrientation = deviceOrientation;
                    }
                };
            }
            [_deviceOrientationManager startDeviceMotionUpdates];
        } else {
            _deviceOrientationConfig.deviceOrientation = @"";
            if (_deviceOrientationManager) {
                [_deviceOrientationManager stopDeviceMotionUpdates];
            }
        }
    } @catch (NSException * e) {
        SALogError(@"%@ error: %@", self, e);
    }
#endif
}

- (void)enableTrackGPSLocation:(BOOL)enableGPSLocation {
#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_GPS
    dispatch_block_t block = ^{
        self.locationConfig.enableGPSLocation = enableGPSLocation;
        if (enableGPSLocation) {
            if (self.locationManager == nil) {
                self.locationManager = [[SALocationManager alloc] init];
                __weak SensorsAnalyticsSDK *weakSelf = self;
                self.locationManager.updateLocationBlock = ^(CLLocation * location, NSError *error) {
                    __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
                    if (location) {
                        strongSelf.locationConfig.coordinate = location.coordinate;
                    }
                    if (error) {
                        SALogError(@"enableTrackGPSLocation error：%@", error);
                    }
                };
            }
            [self.locationManager startUpdatingLocation];
        } else {
            if (self.locationManager != nil) {
                [self.locationManager stopUpdatingLocation];
            }
        }
    };
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
#endif
}

- (void)clearKeychainData {
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAUdidAccount service:kSAService];
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAAppInstallationAccount service:kSAService];
    [SAKeyChainItemWrapper deletePasswordWithAccount:kSAAppInstallationWithDisableCallbackAccount service:kSAService];
#endif

}

- (void)setSecurityPolicy:(SASecurityPolicy *)securityPolicy {
    self.network.securityPolicy = securityPolicy;
}

- (SASecurityPolicy *)securityPolicy {
    return self.network.securityPolicy;
}

@end


#pragma mark - JSCall

@implementation SensorsAnalyticsSDK (JSCall)

#pragma mark about webView

- (void)addWebViewUserAgentSensorsDataFlag {
    [self addWebViewUserAgentSensorsDataFlag:YES];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify  {
    [self addWebViewUserAgentSensorsDataFlag:enableVerify userAgent:nil];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify userAgent:(nullable NSString *)userAgent {

    void (^changeUserAgent)(BOOL verify, NSString *oldUserAgent) = ^void (BOOL verify, NSString *oldUserAgent) {
        NSString *newAgent = oldUserAgent;
        if ([oldUserAgent rangeOfString:@"sa-sdk-ios"].location == NSNotFound) {
            if (verify) {
                newAgent = [oldUserAgent stringByAppendingString:[NSString stringWithFormat: @" /sa-sdk-ios/sensors-verify/%@?%@ ", self.network.host, self.network.project]];
            } else {
                newAgent = [oldUserAgent stringByAppendingString:@" /sa-sdk-ios"];
            }
        }
        //使 newAgent 生效，并设置 userAgent
        NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
        self.userAgent = newAgent;
        [[NSUserDefaults standardUserDefaults] synchronize];
    };

    dispatch_block_t mainThreadBlock = ^(){
        BOOL verify = enableVerify;
        @try {
            if (![self.network isValidServerURL]) {
                verify = NO;
            }
            NSString *oldAgent = userAgent.length > 0 ? userAgent : self.userAgent;
            if (oldAgent) {
                changeUserAgent(verify, oldAgent);
            } else {
                [self loadUserAgentWithCompletion:^(NSString *ua) {
                    changeUserAgent(verify, ua);
                }];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@: %@", self, exception);
        }
    };
    sensorsdata_dispatch_main_safe_sync(mainThreadBlock);
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request {
    return [self showUpWebView:webView WithRequest:request andProperties:nil];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify {
    return [self showUpWebView:webView WithRequest:request andProperties:nil enableVerify:enableVerify];
}


- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict {
    return [self showUpWebView:webView WithRequest:request andProperties:propertyDict enableVerify:NO];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict enableVerify:(BOOL)enableVerify {
    if (![self shouldHandleWebView:webView request:request]) {
        return NO;
    }
    @try {
        SALogDebug(@"showUpWebView");
        SAJSONUtil *_jsonUtil = [[SAJSONUtil alloc] init];
        NSDictionary *bridgeCallbackInfo = [self webViewJavascriptBridgeCallbackInfo];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (bridgeCallbackInfo) {
            [properties addEntriesFromDictionary:bridgeCallbackInfo];
        }
        if (propertyDict) {
            [properties addEntriesFromDictionary:propertyDict];
        }
        NSData* jsonData = [_jsonUtil JSONSerializeObject:properties];
        NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];

        //判断系统是否支持WKWebView
        Class wkWebViewClass = NSClassFromString(@"WKWebView");

        NSString *urlstr = request.URL.absoluteString;
        if (!urlstr) {
            return YES;
        }

         //解析参数
        NSMutableDictionary *paramsDic = [[SAURLUtils queryItemsWithURLString:urlstr] mutableCopy];

#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
        NSAssert(![webView isKindOfClass:NSClassFromString(@"UIWebView")], @"当前集成方式已禁用 UIWebView！❌");
#else

        if ([webView isKindOfClass:[UIWebView class]]) {//UIWebView
            SALogDebug(@"showUpWebView: UIWebView");
            if ([urlstr rangeOfString:SA_JS_GET_APP_INFO_SCHEME].location != NSNotFound) {
                [webView stringByEvaluatingJavaScriptFromString:js];
            } else if ([urlstr rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:SA_EVENT_NAME];
                    if (eventInfo != nil) {
                        NSString* encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else
#endif
        if (wkWebViewClass && [webView isKindOfClass:wkWebViewClass]) {//WKWebView
            SALogDebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:SA_JS_GET_APP_INFO_SCHEME].location != NSNotFound) {
                typedef void(^Myblock)(id, NSError *);
                Myblock myBlock = ^(id _Nullable response, NSError * _Nullable error) {
                    SALogDebug(@"response: %@ error: %@", response, error);
                };
                SEL sharedManagerSelector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
                if (sharedManagerSelector) {
                    ((void (*)(id, SEL, NSString *, Myblock))[webView methodForSelector:sharedManagerSelector])(webView, sharedManagerSelector, js, myBlock);
                }
            } else if ([urlstr rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].location != NSNotFound) {
                if ([paramsDic count] > 0) {
                    NSString *eventInfo = [paramsDic objectForKey:SA_EVENT_NAME];
                    if (eventInfo != nil) {
                        NSString* encodedString = [eventInfo stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        [self trackFromH5WithEvent:encodedString enableVerify:enableVerify];
                    }
                }
            }
        } else {
            SALogDebug(@"showUpWebView: not UIWebView or WKWebView");
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    } @finally {
        return YES;
    }
}


- (BOOL)shouldHandleWebView:(id)webView request:(NSURLRequest *)request {
    if (webView == nil) {
        SALogDebug(@"showUpWebView == nil");
        return NO;
    }

    if (request == nil || ![request isKindOfClass:NSURLRequest.class]) {
        SALogDebug(@"request == nil or not NSURLRequest class");
        return NO;
    }

    NSString *urlString = request.URL.absoluteString;
    if ([urlString rangeOfString:SA_JS_GET_APP_INFO_SCHEME].length ||[urlString rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].length) {
        return YES;
    }
    return NO;
}

#pragma mark trackFromH5
- (void)trackFromH5WithEvent:(NSString *)eventInfo {
    [self trackFromH5WithEvent:eventInfo enableVerify:NO];
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify {
    dispatch_async(self.serialQueue, ^{
        @try {
            if (eventInfo == nil) {
                return;
            }

            NSData *jsonData = [eventInfo dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&error];
            if(error || !eventDict) {
                return;
            }

            if (enableVerify) {
                NSString *serverUrl = [eventDict valueForKey:@"server_url"];
                if (![self.network isSameProjectWithURLString:serverUrl]) {
                    SALogError(@"Server_url verified faild, Web event lost! Web server_url = '%@'",serverUrl);
                    return;
                }
            }

            NSString *type = [eventDict valueForKey:SA_EVENT_TYPE];
            NSString *bestId = self.distinctId;
            NSNumber *timeStamp = @([[self class] getCurrentTime]);

            if([type isEqualToString:@"track_signup"]) {
                NSString *realOriginalId = self.originalId ?: self.distinctId;
                [eventDict setValue:realOriginalId forKey:@"original_id"];
            } else {
                [eventDict setValue:bestId forKey:SA_EVENT_DISTINCT_ID];
            }
            [eventDict setValue:@(arc4random()) forKey:SA_EVENT_TRACK_ID];

            NSDictionary *libDict = [eventDict objectForKey:SA_EVENT_LIB];
            id app_version = [self->_automaticProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            if (app_version) {
                [libDict setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            }

            //update lib $app_version from super properties
            app_version = [self->_superProperties objectForKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            if (app_version) {
                [libDict setValue:app_version forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
            }

            NSMutableDictionary *automaticPropertiesCopy = [NSMutableDictionary dictionaryWithDictionary:self->_automaticProperties];
            [automaticPropertiesCopy removeObjectForKey:SA_EVENT_COMMON_PROPERTY_LIB];
            [automaticPropertiesCopy removeObjectForKey:SA_EVENT_COMMON_PROPERTY_LIB_VERSION];

            NSMutableDictionary *propertiesDict = [eventDict objectForKey:SA_EVENT_PROPERTIES];
            if([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
                // track / track_signup 类型的请求，还是要加上各种公共property
                // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties,dynamicSuperPropertiesDict,propertieDict
                [propertiesDict addEntriesFromDictionary:automaticPropertiesCopy];
                NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties?self.dynamicSuperProperties():nil;
                //去重
                [self unregisterSameLetterSuperProperties:dynamicSuperPropertiesDict];
                [propertiesDict addEntriesFromDictionary:self->_superProperties];
                [propertiesDict addEntriesFromDictionary:dynamicSuperPropertiesDict];

                // 每次 track 时手机网络状态
                NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
                [propertiesDict setObject:networkType forKey:SA_EVENT_COMMON_PROPERTY_NETWORK_TYPE];
                if ([networkType isEqualToString:@"WIFI"]) {
                    [propertiesDict setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
                } else {
                    [propertiesDict setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_WIFI];
                }

                //  是否首日访问
                if([type isEqualToString:@"track"]) {
                    if ([self isFirstDay]) {
                        [propertiesDict setObject:@YES forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
                    } else {
                        [propertiesDict setObject:@NO forKey:SA_EVENT_COMMON_PROPERTY_IS_FIRST_DAY];
                    }
                }
                [propertiesDict removeObjectForKey:@"_nocache"];

                // 添加 DeepLink 来源渠道参数。优先级最高，覆盖 H5 传过来的同名字段
                [propertiesDict addEntriesFromDictionary:[self.linkHandler latestUtmProperties]];
            }

            [eventDict removeObjectForKey:@"_nocache"];
            [eventDict removeObjectForKey:@"server_url"];
            

            // $project & $token
            NSString *project = [propertiesDict objectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
            NSString *token = [propertiesDict objectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
            NSNumber *timeNumber = propertiesDict[SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];

            if (project) {
                [propertiesDict removeObjectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
                [eventDict setValue:project forKey:SA_EVENT_PROJECT];
            }
            if (token) {
                [propertiesDict removeObjectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
                [eventDict setValue:token forKey:SA_EVENT_TOKEN];
            }
            if (timeNumber) { //包含 $time
                NSInteger customTimeInt = [timeNumber integerValue];
                if (customTimeInt  >= SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME_INT) {
                    timeStamp = @(customTimeInt);
                } else {
                    SALogError(@"H5 $time error '%@'，Please check the value", timeNumber);
                }
                [propertiesDict removeObjectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TIME];
            }

            [eventDict setValue:timeStamp forKey:SA_EVENT_TIME];

            //JS SDK Data add _hybrid_h5 flag
            [eventDict setValue:@(YES) forKey:SA_EVENT_HYBRID_H5];

            NSDictionary *enqueueEvent = [self willEnqueueWithType:type andEvent:eventDict];
            if (!enqueueEvent) {
                return;
            }
            SALogDebug(@"\n【track event from H5】:\n%@", enqueueEvent);

            if([type isEqualToString:@"track_signup"]) {

                NSString *newLoginId = [eventDict objectForKey:SA_EVENT_DISTINCT_ID];

                if (![newLoginId isEqualToString:self.loginId]) {
                    self.loginId = newLoginId;
                    [self archiveLoginId];
                    if (![newLoginId isEqualToString:self.anonymousId]) {
                        self.originalId = self.anonymousId;
                        [self enqueueWithType:type andEvent:[enqueueEvent copy]];
                    }
                }
            } else {
                [self enqueueWithType:type andEvent:[enqueueEvent copy]];
            }
        } @catch (NSException *exception) {
            SALogError(@"%@: %@", self, exception);
        }
    });
}
@end


#pragma mark - People analytics

@implementation SensorsAnalyticsPeople

- (void)set:(NSDictionary *)profileDict {
    if (profileDict) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:profileDict withType:SA_PROFILE_SET];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    if (profileDict) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:profileDict withType:SA_PROFILE_SET_ONCE];
    }
}

- (void)set:(NSString *) profile to:(id)content {
    if (profile && content) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{profile: content} withType:SA_PROFILE_SET];
    }
}

- (void)setOnce:(NSString *) profile to:(id)content {
    if (profile && content) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{profile: content} withType:SA_PROFILE_SET_ONCE];
    }
}

- (void)unset:(NSString *) profile {
    if (profile) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{profile: @""} withType:SA_PROFILE_UNSET];
    }
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    if (profile && amount) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{profile: amount} withType:SA_PROFILE_INCREMENT];
    }
}

- (void)increment:(NSDictionary *)profileDict {
    if (profileDict) {
        [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:profileDict withType:SA_PROFILE_INCREMENT];
    }
}

- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content {
    if (profile && content) {
        if ([content isKindOfClass:[NSSet class]] || [content isKindOfClass:[NSArray class]]) {
            [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{profile: content} withType:SA_PROFILE_APPEND];
        }
    }
}

- (void)deleteUser {
    [[SensorsAnalyticsSDK sharedInstance] track:nil withProperties:@{} withType:SA_PROFILE_DELETE];
}

@end

#pragma mark - Deprecated
@implementation SensorsAnalyticsSDK (Deprecated)

+ (SensorsAnalyticsSDK *)sharedInstanceWithConfig:(nonnull SAConfigOptions *)configOptions {
    [self startWithConfigOptions:configOptions];
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    return [SensorsAnalyticsSDK sharedInstanceWithServerURL:serverURL
                                           andLaunchOptions:nil andDebugMode:debugMode];
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                    andLaunchOptions:(NSDictionary *)launchOptions
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    NSAssert(sensorsdata_is_same_queue(dispatch_get_main_queue()), @"神策 iOS SDK 必须在主线程里进行初始化，否则会引发无法预料的问题（比如丢失 $AppStart 事件）。");
    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[self alloc] initWithServerURL:serverURL
                                        andLaunchOptions:launchOptions
                                            andDebugMode:debugMode];
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nonnull NSString *)serverURL
                                    andLaunchOptions:(NSDictionary * _Nullable)launchOptions {
    NSAssert(sensorsdata_is_same_queue(dispatch_get_main_queue()), @"神策 iOS SDK 必须在主线程里进行初始化，否则会引发无法预料的问题（比如丢失 $AppStart 事件）。");
    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[self alloc] initWithServerURL:serverURL
                                        andLaunchOptions:launchOptions
                                            andDebugMode:SensorsAnalyticsDebugOff];
    });
    return sharedInstance;
}

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

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    [self configServerURLWithDebugMode:debugMode  showDebugModeWarning:NO];
}

- (void)enableAutoTrack {
    [self enableAutoTrack:SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppViewScreen];
}

- (void)ignoreAutoTrackEventType:(SensorsAnalyticsAutoTrackEventType)eventType {
    self.configOptions.autoTrackEventType = self.configOptions.autoTrackEventType ^ eventType;
}

- (BOOL)isViewControllerStringIgnored:(NSString *)viewControllerClassName {
    if (viewControllerClassName == nil) {
        return NO;
    }
    
    if (_ignoredViewControllers.count > 0 && [_ignoredViewControllers containsObject:viewControllerClassName]) {
        return YES;
    }
    return NO;
}

- (void)trackTimerBegin:(NSString *)event {
    [self trackTimerStart:event];
}

- (void)trackTimerBegin:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerStart:event timeUnit:timeUnit currentSysUpTime:currentSysUpTime];
    });
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

- (void)trackSignUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertieDict {
    [self identify:newDistinctId];
    [self track:SA_EVENT_NAME_APP_SIGN_UP withProperties:propertieDict withType:@"track_signup"];
}

- (void)trackSignUp:(NSString *)newDistinctId {
    [self trackSignUp:newDistinctId withProperties:nil];
}

- (BOOL)handleHeatMapUrl:(NSURL *)URL {
    return [self handleAutoTrackURL:URL];
}

- (void)enableVisualizedAutoTrack {
    self.configOptions.enableVisualizedAutoTrack = YES;
}

- (void)enableHeatMap {
    self.configOptions.enableHeatMap = YES;
}

- (void)trackViewScreen:(NSString *)url withProperties:(NSDictionary *)properties {
    NSMutableDictionary *trackProperties = [[NSMutableDictionary alloc] init];
    if (properties) {
        [trackProperties addEntriesFromDictionary:properties];
    }
    @synchronized(_lastScreenTrackProperties) {
        _lastScreenTrackProperties = properties;
    }
    
    [trackProperties setValue:url forKey:SA_EVENT_PROPERTY_SCREEN_URL];
    @synchronized(_referrerScreenUrl) {
        if (_referrerScreenUrl) {
            [trackProperties setValue:_referrerScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_REFERRER_URL];
        }
        _referrerScreenUrl = url;
    }
    [self track:SA_EVENT_NAME_APP_VIEW_SCREEN withProperties:trackProperties withTrackType:SensorsAnalyticsTrackTypeAuto];
}
@end
