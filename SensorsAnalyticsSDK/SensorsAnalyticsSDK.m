//  SensorsAnalyticsSDK.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#include <sys/sysctl.h>
#include <stdlib.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "JSONUtil.h"
#import "SAGzipUtility.h"
#import "MessageQueueBySqlite.h"
#import "SALogger.h"
#import "SAReachability.h"
#import "SASwizzler.h"
#import "SensorsAnalyticsSDK.h"
#import "UIApplication+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SASwizzle.h"
#import "AutoTrackUtils.h"
#import "NSString+HashCode.h"
#import "SensorsAnalyticsExceptionHandler.h"
#import "SAServerUrl.h"
#import "SAAppExtensionDataManager.h"

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
     #import "SAKeyChainItemWrapper.h"
#endif

#import "SASDKRemoteConfig.h"
#import "SADeviceOrientationManager.h"
#import "SALocationManager.h"
#import "UIView+AutoTrack.h"
#import "NSThread+SAHelpers.h"
#import "SACommonUtility.h"
#import "SAConstants.h"
#import "UIGestureRecognizer+AutoTrack.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAlertController.h"
#import "SAAuxiliaryToolManager.h"


#define VERSION @"1.11.0"

static NSUInteger const SA_PROPERTY_LENGTH_LIMITATION = 8191;

static NSString* const SA_JS_GET_APP_INFO_SCHEME = @"sensorsanalytics://getAppInfo";
static NSString* const SA_JS_TRACK_EVENT_NATIVE_SCHEME = @"sensorsanalytics://trackEvent";
//中国运营商 mcc 标识
static NSString* const CARRIER_CHINA_MCC = @"460";

void *SensorsAnalyticsQueueTag = &SensorsAnalyticsQueueTag;

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
    UIResponder *next = self.nextResponder;
    do {
        if ([next isKindOfClass:UIViewController.class]) {
            UIViewController *vc = (UIViewController *)next;
            if ([vc isKindOfClass:UINavigationController.class]) {
                next = [(UINavigationController *)vc topViewController];
                break;
            } else if([vc isKindOfClass:UITabBarController.class]) {
                next = [(UITabBarController *)vc selectedViewController];
                break;
            }
            UIViewController *parentVC = vc.parentViewController;
            if (parentVC) {
                if ([parentVC isKindOfClass:UINavigationController.class]||
                    [parentVC isKindOfClass:UITabBarController.class]||
                    [parentVC isKindOfClass:UIPageViewController.class]||
                    [parentVC isKindOfClass:UISplitViewController.class]) {
                    break;
                }
            } else {
                break;
            }
        }
    } while ((next=next.nextResponder));
    return [next isKindOfClass:UIViewController.class]?(UIViewController *)next:nil;
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

- (id)sensorsAnalyticsDelegate {
    return objc_getAssociatedObject(self, @"sensorsAnalyticsDelegate");
}

- (void)setSensorsAnalyticsDelegate:(id)sensorsAnalyticsDelegate {
    objc_setAssociatedObject(self, @"sensorsAnalyticsDelegate", sensorsAnalyticsDelegate, OBJC_ASSOCIATION_ASSIGN);
}
@end

@interface SAConfigOptions()
/**
 数据接收地址 Url
 */
@property (nonatomic, copy) NSString *serverURL;
/**
 App 启动的 launchOptions
 */
@property (nonatomic, copy) NSDictionary *launchOptions;
@end

@implementation SAConfigOptions

- (instancetype)initWithServerURL:(NSString *)serverURL launchOptions:(NSDictionary *)launchOptions {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _launchOptions = launchOptions;
    }
    return self;
}

@end

static SensorsAnalyticsSDK *sharedInstance = nil;

@interface SensorsAnalyticsSDK()

// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;

@property (atomic, copy) NSString *serverURL;

@property (atomic, copy) NSString *distinctId;
@property (atomic, copy) NSString *originalId;
@property (atomic, copy) NSString *loginId;
@property (atomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *superProperties;
@property (nonatomic, strong) NSMutableDictionary *trackTimer;

@property (nonatomic, strong) NSPredicate *regexTestName;

@property (nonatomic, strong) NSPredicate *regexEventName;

@property (atomic, strong) MessageQueueBySqlite *messageQueue;

@property (nonatomic, strong) NSTimer *timer;

//用户设置的不被AutoTrack的Controllers
@property (nonatomic, strong) NSMutableArray *ignoredViewControllers;

@property (nonatomic, strong) NSMutableSet<NSString *> *heatMapViewControllers;
@property (nonatomic, strong) NSMutableSet<NSString *> *visualizedAutoTrackViewControllers;

@property (nonatomic, strong) NSMutableArray *ignoredViewTypeList;

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

@property (nonatomic, copy) void(^reqConfigBlock)(BOOL success , NSDictionary *configDict);
@property (nonatomic, assign) NSUInteger pullSDKConfigurationRetryMaxCount;

@property (nonatomic, copy) NSDictionary<NSString *, id> *(^dynamicSuperProperties)(void);
@property (nonatomic, copy) BOOL (^trackEventCallback)(NSString *, NSMutableDictionary<NSString *, id> *);

///是否为被动启动
@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;
@property (nonatomic, strong) NSMutableArray <UIViewController *> *launchedPassivelyControllers;
@end

@implementation SensorsAnalyticsSDK {
    SensorsAnalyticsDebugMode _debugMode;
    UInt64 _flushBulkSize;
    UInt64 _flushInterval;
    UInt64 _maxCacheSize;
    NSDateFormatter *_dateFormatter;
    BOOL _autoTrack;                    // 自动采集事件
    BOOL _appRelaunched;                // App 从后台恢复
    BOOL _showDebugAlertView;
    BOOL _shouldHeatMap;
    BOOL _shouldVisualizedAutoTrack;
    UInt8 _debugAlertViewHasShownNumber;
    NSString *_referrerScreenUrl;
    NSDictionary *_lastScreenTrackProperties;
    BOOL _applicationWillResignActive;
    BOOL _clearReferrerWhenAppEnd;
	SensorsAnalyticsAutoTrackEventType _autoTrackEventType;
    SensorsAnalyticsNetworkType _networkTypePolicy;
    NSString *_deviceModel;
    NSString *_osVersion;
    NSString *_userAgent;
    NSString *_originServerUrl;
    NSString *_cookie;
}

@synthesize remoteConfig = _remoteConfig;

#pragma mark - Initialization

+ (SensorsAnalyticsSDK *)sharedInstanceWithConfig:(nonnull SAConfigOptions *)configOptions {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithServerURL:configOptions.serverURL
                                        andLaunchOptions:configOptions.launchOptions
                                            andDebugMode:SensorsAnalyticsDebugOff];
        
        sharedInstance.configOptions = configOptions;
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *_Nullable)sharedInstance {
    if (sharedInstance.remoteConfig.disableSDK) {
        return nil;
    }
    return sharedInstance;
}

+ (UInt64)getCurrentTime {
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    return time;
}

+ (UInt64)getSystemUpTime {
    UInt64 time = NSProcessInfo.processInfo.systemUptime * 1000;
    return time;
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
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    return distinctId;
}

+ (NSString *)getUserAgent {
    //在此之前调用过 addWebViewUserAgentSensorsDataFlag ，可以直接从 _userAgent 获取 ua
    __block  NSString *currentUA = self.sharedInstance->_userAgent;
    if (currentUA  == nil)  {
        if ([NSThread isMainThread]) {
            UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
            currentUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
            self.sharedInstance->_userAgent = currentUA;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                currentUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                self.sharedInstance->_userAgent = currentUA;
            });
        }
    }
    return currentUA;
}

- (BOOL)shouldTrackViewScreen:(UIViewController *)controller {
    static NSSet *blacklistedClasses = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
        //文件路径
        NSString *jsonPath = [sensorsBundle pathForResource:@"sa_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        @try {
            NSArray *blacklistedViewControllerClassNames = [NSJSONSerialization JSONObjectWithData:jsonData  options:NSJSONReadingAllowFragments  error:nil];
            blacklistedClasses = [NSSet setWithArray:blacklistedViewControllerClassNames];
        } @catch(NSException *exception) {  // json加载和解析可能失败
            SAError(@"%@ error: %@", self, exception);
        }
    });
    
    __block BOOL shouldTrack = YES;
    [blacklistedClasses enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *blackClassName = (NSString *)obj;
        Class blackClass = NSClassFromString(blackClassName);
        if (blackClass && [controller isKindOfClass:blackClass]) {
            shouldTrack = NO;
            *stop = YES;
        }
    }];
    return shouldTrack;
}

- (instancetype)initWithServerURL:(NSString *)serverURL
                    andLaunchOptions:(NSDictionary *)launchOptions
                     andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    @try {
        if (self = [self init]) {
            _autoTrackEventType = SensorsAnalyticsEventTypeNone;
            _networkTypePolicy = SensorsAnalyticsNetworkType3G | SensorsAnalyticsNetworkType4G | SensorsAnalyticsNetworkTypeWIFI;

            [NSThread sa_safelyRunOnMainThreadSync:^{
                UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
                //判断被动启动
                if (applicationState == UIApplicationStateBackground) {
                    self->_launchedPassively = YES;
                }
            }];
           
            _people = [[SensorsAnalyticsPeople alloc] init];

            _debugMode = debugMode;
            [self enableLog];
            [self setServerUrl:serverURL];
            
            _flushInterval = 15 * 1000;
            _flushBulkSize = 100;
            _maxCacheSize = 10000;
            _autoTrack = NO;
            _appRelaunched = NO;
            _showDebugAlertView = YES;
            _debugAlertViewHasShownNumber = 0;
            _referrerScreenUrl = nil;
            _lastScreenTrackProperties = nil;
            _applicationWillResignActive = NO;
            _clearReferrerWhenAppEnd = NO;
            _pullSDKConfigurationRetryMaxCount = 3;// SDK 开启关闭功能接口最大重试次数

            NSString *label = [NSString stringWithFormat:@"com.sensorsdata.serialQueue.%p", self];
            self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(self.serialQueue, SensorsAnalyticsQueueTag, &SensorsAnalyticsQueueTag, NULL);
            
            NSString *readWriteLabel = [NSString stringWithFormat:@"com.sensorsdata.readWriteQueue.%p", self];
            self.readWriteQueue = dispatch_queue_create([readWriteLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            
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
            _dateFormatter = [[NSDateFormatter alloc] init];
            [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

            self.flushBeforeEnterBackground = YES;

            self.messageQueue = [[MessageQueueBySqlite alloc] initWithFilePath:[self filePathForData:@"message-v2"]];
            if (self.messageQueue == nil) {
                SADebug(@"SqliteException: init Message Queue in Sqlite fail");
            }

            // 取上一次进程退出时保存的distinctId、loginId、superProperties
            [self unarchive];

            if (self.firstDay == nil) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
                [self archiveFirstDay];
            }

            self.automaticProperties = [self collectAutomaticProperties];
            self.trackTimer = [NSMutableDictionary dictionary];

            NSString *namePattern = @"^((?!^distinct_id$|^original_id$|^time$|^event$|^properties$|^id$|^first_id$|^second_id$|^users$|^events$|^event$|^user_id$|^date$|^datetime$)[a-zA-Z_$][a-zA-Z\\d_$]{0,99})$";
            self.regexTestName = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", namePattern];
            
            NSString *eventPattern = @"^\\$((AppEnd)|(AppStart)|(AppViewScreen)|(AppClick)|(SignUp))|(^AppCrashed)$";
            self.regexEventName = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", eventPattern];
            
            
            
            [self setUpListeners];
            
            // XXX: App Active 的时候会启动计时器，此处不需要启动
            //        [self startFlushTimer];
            NSString *logMessage = nil;
            logMessage = [NSString stringWithFormat:@"%@ initialized the instance of Sensors Analytics SDK with server url '%@', debugMode: '%@'",
                              self, serverURL, [self debugModeToString:debugMode]];
            SALog(@"%@", logMessage);
            
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
    } @catch(NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    return self;
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
        SAError(@"%@ error: %@", self, exception);
    }
    return [properties copy];
}

- (void)setServerUrl:(NSString *)serverUrl {
    _originServerUrl = serverUrl;
    if (serverUrl == nil || [serverUrl length] == 0 || _debugMode == SensorsAnalyticsDebugOff) {
        _serverURL = serverUrl;
    } else {
        // 将 Server URI Path 替换成 Debug 模式的 '/debug'
        NSURL *tempBaseUrl = [NSURL URLWithString:serverUrl];
        if (tempBaseUrl.lastPathComponent.length > 0) {
            tempBaseUrl = [tempBaseUrl URLByDeletingLastPathComponent];
        }
        NSURL *url = [tempBaseUrl URLByAppendingPathComponent:@"debug"];
        NSString *host = url.host;
        if ([host rangeOfString:@"_"].location != NSNotFound) { //包含下划线日志提示
            NSString * referenceUrl = @"https://en.wikipedia.org/wiki/Hostname";
            SALog(@"Server url:%@ contains '_'  is not recommend,see details:%@", serverUrl, referenceUrl);
        }
        _serverURL = [url absoluteString];
    }
}


- (NSString *)collectRemoteConfigUrl {
    
    @try {
        NSURLComponents *urlComponents = nil;
        
        if (self.configOptions.remoteConfigURL) {
            
            NSURL *url = [NSURL URLWithString:self.configOptions.remoteConfigURL];
            urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        } else {
            
            NSString *urlString = self.serverURL;
            NSURL *url = nil;
            if ([urlString isKindOfClass:NSString.class] && urlString.length) {
                url = [NSURL URLWithString:urlString];
                if (url.lastPathComponent.length > 0) {
                    url = [url URLByDeletingLastPathComponent];
                }
            }
            
            if (!url) {
                SALog(@"serverURL error，unable request remoteConfig");
                return nil;
            }
            urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
            urlComponents.query = nil;
            urlComponents.path = [urlComponents.path stringByAppendingPathComponent:@"/config/iOS.conf"];
        }
        
        if (!urlComponents) {
            SALog(@"URLString is malformed, nil is returned.");
            return nil;
        }
        
        NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:[SAServerUrl analysisQueryItemWithURLComponent:urlComponents]];
        if (self.remoteConfig.v.length) {
            queryDic[@"v"] = self.remoteConfig.v;
        }
        
        NSString *queryString = [SAServerUrl collectURLQueryWithParams:queryDic];
        urlComponents.query = queryString;
        
        return urlComponents.URL.absoluteString;
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
    return nil;
}

- (void)configDebugModeServerUrl {
    if (_debugMode  == SensorsAnalyticsDebugOff ) {
        self.serverURL = _originServerUrl;
    } else {
        [self setServerUrl:_originServerUrl];
    }
}

- (void)disableDebugMode {
    _debugMode = SensorsAnalyticsDebugOff;
    _serverURL = _originServerUrl;
    [self enableLog:NO];
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
                if (self -> _debugMode == SensorsAnalyticsDebugAndTrack) {
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
                self -> _debugMode = debugMode;
                [self enableLog:YES];
                
                alterViewBlock();
                
                [self configDebugModeServerUrl];
                [self debugModeCallBackWithParams:params];
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

- (void)debugModeCallBackWithParams:(NSDictionary<NSString *, id> *)params {
    
    if (!self.serverURL) {
        SAError(@"serverURL error，Please check the serverURL");
        return;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.serverURL];
    NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:[SAServerUrl analysisQueryItemWithURLComponent:urlComponents]];
    //添加参数
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        queryDic[key] = obj;
    }];
    NSString *queryString = [SAServerUrl collectURLQueryWithParams:queryDic];
    urlComponents.query = queryString;
    
    NSURL *callBackUrl = [urlComponents URL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:callBackUrl];
    request.timeoutInterval = 30;
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *callData = @{@"distinct_id":[self getBestId]};
    JSONUtil *jsonUtil = [[JSONUtil alloc] init];
    NSData *jsonData = [jsonUtil JSONSerializeObject:callData];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode == 200) {
            SALog(@"config debugMode CallBack success");
        } else {
            SAError(@"config debugMode CallBack Faild statusCode：%d，url：%@", statusCode, callBackUrl);
        }
    }];
    [task resume];
}

- (BOOL)isFirstDay {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
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
    __block UIViewController *currentVC = nil;
    if ([NSThread isMainThread]) {
        @try {
            UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            if (rootViewController != nil) {
                currentVC = [self getCurrentVCFrom:rootViewController isRoot:YES];
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
        return currentVC;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @try {
                UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
                if (rootViewController != nil) {
                    currentVC = [self getCurrentVCFrom:rootViewController isRoot:YES];
                }
            } @catch (NSException *exception) {
                SAError(@"%@ error: %@", self, exception);
            }
        });
        return currentVC;
    }
}

- (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC isRoot:(BOOL)isRoot{
    @try {
        UIViewController *currentVC;
        if ([rootVC presentedViewController]) {
            // 视图是被presented出来的
            rootVC = [self getCurrentVCFrom:rootVC.presentedViewController isRoot:NO];
        }
        
        if ([rootVC isKindOfClass:[UITabBarController class]]) {
            // 根视图为UITabBarController
            currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController] isRoot:NO];
        } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
            // 根视图为UINavigationController
            currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController] isRoot:NO];
        } else {
            // 根视图为非导航类
            if ([rootVC respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                UIViewController *tempViewController = [rootVC performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
                if (tempViewController) {
                    currentVC = [self getCurrentVCFrom:tempViewController isRoot:NO];
                }
            } else {
                if (rootVC.childViewControllers && rootVC.childViewControllers.count == 1 && isRoot) {
                    currentVC = [self getCurrentVCFrom:rootVC.childViewControllers[0] isRoot:NO];
                }
                else {
                    currentVC = rootVC;
                }
            }
        }
        
        return currentVC;
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify {
    dispatch_async(self.serialQueue, ^{
        @try {
            if (eventInfo == nil) {
                return;
            }

            NSData *jsonData = [eventInfo dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSMutableDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&err];
            if(err) {
                return;
            }

            if (!eventDict) {
                return;
            }

            if (enableVerify) {
                NSString *serverUrl = [eventDict valueForKey:@"server_url"];
                if (serverUrl != nil) {
                    SAServerUrl *h5ServerUrl = [[SAServerUrl alloc] initWithUrl:serverUrl];
                    SAServerUrl *appServerUrl = [[SAServerUrl alloc] initWithUrl:self->_serverURL];
                    if (![appServerUrl check:h5ServerUrl]) {
                        return;
                    }
                } else {
                    //防止 H5 集成的 JS SDK 版本太老，没有发 server_url
                    return;
                }
            }

            NSString *type = [eventDict valueForKey:SA_EVENT_TYPE];
            NSString *bestId = self.getBestId;

            [eventDict setValue:@([[self class] getCurrentTime]) forKey:SA_EVENT_TIME];

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
                [propertiesDict addEntriesFromDictionary:self->_superProperties];
                NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties?self.dynamicSuperProperties():nil;
                //去重
                [self unregisterSameLetterSuperProperties:dynamicSuperPropertiesDict];
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
            }

            [eventDict removeObjectForKey:@"_nocache"];
            [eventDict removeObjectForKey:@"server_url"];

            // $project & $token
            NSString *project = [propertiesDict objectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
            NSString *token = [propertiesDict objectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
            if (project) {
                [propertiesDict removeObjectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT];
                [eventDict setValue:project forKey:SA_EVENT_PROJECT];
            }
            if (token) {
                [propertiesDict removeObjectForKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN];
                [eventDict setValue:token forKey:SA_EVENT_TOKEN];
            }

            NSDictionary *enqueueEvent = [self willEnqueueWithType:type andEvent:eventDict];
            if (!enqueueEvent) {
                return;
            }
            SALog(@"\n【track event from H5】:\n%@", enqueueEvent);

            if([type isEqualToString:@"track_signup"]) {

                NSString *newLoginId = [eventDict objectForKey:SA_EVENT_DISTINCT_ID];

                if (![newLoginId isEqualToString:[self loginId]]) {
                    self.loginId = newLoginId;
                    [self archiveLoginId];
                    if (![newLoginId isEqualToString:[self distinctId]]) {
                        self.originalId = [self distinctId];
                        [self enqueueWithType:type andEvent:[enqueueEvent copy]];
                    }
                }
            } else {
                [self enqueueWithType:type andEvent:[enqueueEvent copy]];
            }
        } @catch (NSException *exception) {
            SAError(@"%@: %@", self, exception);
        }
    });
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo {
    [self trackFromH5WithEvent:eventInfo enableVerify:NO];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request {
    return [self showUpWebView:webView WithRequest:request andProperties:nil];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request enableVerify:(BOOL)enableVerify {
    return [self showUpWebView:webView WithRequest:request andProperties:nil enableVerify:enableVerify];
}

- (BOOL)shouldHandleWebView:(id)webView request:(NSURLRequest *)request {
    if (webView == nil) {
        SADebug(@"showUpWebView == nil");
        return NO;
    }

    if (request == nil || ![request isKindOfClass:NSURLRequest.class]) {
        SADebug(@"request == nil or not NSURLRequest class");
        return NO;
    }

    NSString *urlString = request.URL.absoluteString;
    if ([urlString rangeOfString:SA_JS_GET_APP_INFO_SCHEME].length ||[urlString rangeOfString:SA_JS_TRACK_EVENT_NATIVE_SCHEME].length) {
        return YES;
    }
    return NO;
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict enableVerify:(BOOL)enableVerify {
    if (![self shouldHandleWebView:webView request:request]) {
        return NO;
    }
    @try {
        SADebug(@"showUpWebView");
        JSONUtil *_jsonUtil = [[JSONUtil alloc] init];
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
        
        NSURLComponents *urlComponents = [NSURLComponents componentsWithString:urlstr];
         //解析参数
        NSMutableDictionary *paramsDic = [NSMutableDictionary dictionaryWithDictionary:[SAServerUrl analysisQueryItemWithURLComponent:urlComponents]];
        
        if ([webView isKindOfClass:[UIWebView class]]) {//UIWebView
            SADebug(@"showUpWebView: UIWebView");
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
        } else if(wkWebViewClass && [webView isKindOfClass:wkWebViewClass]) {//WKWebView
            SADebug(@"showUpWebView: WKWebView");
            if ([urlstr rangeOfString:SA_JS_GET_APP_INFO_SCHEME].location != NSNotFound) {
                typedef void(^Myblock)(id, NSError *);
                Myblock myBlock = ^(id _Nullable response, NSError * _Nullable error) {
                    SALog(@"response: %@ error: %@", response, error);
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
            SADebug(@"showUpWebView: not UIWebView or WKWebView");
        }
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
    } @finally {
        return YES;
    }
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict {
    return [self showUpWebView:webView WithRequest:request andProperties:propertyDict enableVerify:NO];
}

- (void)setMaxCacheSize:(UInt64)maxCacheSize {
    if (maxCacheSize > 0) {
        //防止设置的值太小导致事件丢失
        if (maxCacheSize < 10000) {
            maxCacheSize = 10000;
        }
        _maxCacheSize = maxCacheSize;
    }
}

- (UInt64)getMaxCacheSize {
    return _maxCacheSize;
}

- (NSMutableDictionary *)webViewJavascriptBridgeCallbackInfo {
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"iOS" forKey:SA_EVENT_TYPE];
    if ([self loginId] != nil) {
        [libProperties setValue:[self loginId] forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else {
        [libProperties setValue:[self distinctId] forKey:SA_EVENT_DISTINCT_ID];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}

- (void)login:(NSString *)loginId {
    [self login:loginId withProperties:nil];
}

- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties {
    if (loginId == nil || loginId.length == 0) {
        SAError(@"%@ cannot login blank login_id: %@", self, loginId);
        return;
    }
    if (loginId.length > 255) {
        SAError(@"%@ max length of login_id is 255, login_id: %@", self, loginId);
        return;
    }
    if (![loginId isEqualToString:[self loginId]]) {
        self.loginId = loginId;
        [self archiveLoginId];
        if (![loginId isEqualToString:[self distinctId]]) {
            self.originalId = [self distinctId];
            [self track:SA_EVENT_NAME_APP_SIGN_UP withProperties:properties withType:@"track_signup"];
        }
    }
}

- (void)logout {
    self.loginId = nil;
    [self archiveLoginId];
}

- (NSString *)anonymousId {
    return _distinctId;
}

- (void)resetAnonymousId {
    self.distinctId = [[self class] getUniqueHardwareId];
    [self archiveDistinctId];
}

- (void)trackAppCrash {
    // Install uncaught exception handlers first
    [[SensorsAnalyticsExceptionHandler sharedHandler] addSensorsAnalyticsInstance:self];
}

- (void)enableAutoTrack:(SensorsAnalyticsAutoTrackEventType)eventType {
    if (_autoTrackEventType != eventType) {
        _autoTrackEventType = eventType;
        _autoTrack = (_autoTrackEventType != SensorsAnalyticsEventTypeNone);
        [self _enableAutoTrack];
    }
    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SA_HAS_LAUNCHED_ONCE]) {
        isFirstStart = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SA_HAS_LAUNCHED_ONCE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self isLaunchedPassively]) {
            // 追踪 AppStart 事件
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {

                [self track:SA_EVENT_NAME_APP_START_PASSIVELY withProperties:@{
                                                                   SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND : @(self->_appRelaunched),
                                                                   SA_EVENT_PROPERTY_APP_FIRST_START : @(isFirstStart),
                                                             } withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
        } else {
            // 追踪 AppStart 事件
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
                [self track:SA_EVENT_NAME_APP_START withProperties:@{
                                                             SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND : @(self->_appRelaunched),
                                                             SA_EVENT_PROPERTY_APP_FIRST_START : @(isFirstStart),
                                                             } withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
            // 启动 AppEnd 事件计时器
            if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
                [self trackTimer:SA_EVENT_NAME_APP_END withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
            }
        }
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
    return _autoTrack;
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
    return !(_autoTrackEventType & eventType);
}

- (void)ignoreViewType:(Class)aClass {
    [_ignoredViewTypeList addObject:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    return [_ignoredViewTypeList containsObject:aClass];
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    if (viewController == nil) {
        return false;
    }
    NSString *screenName = NSStringFromClass([viewController class]);
    if (_ignoredViewControllers != nil && _ignoredViewControllers.count > 0) {
        if ([_ignoredViewControllers containsObject:screenName]) {
            return true;
        }
    }
    return false;
}

- (BOOL)isViewControllerStringIgnored:(NSString *)viewControllerString {
    if (viewControllerString == nil) {
        return false;
    }

    if (_ignoredViewControllers != nil && _ignoredViewControllers.count > 0) {
        if ([_ignoredViewControllers containsObject:viewControllerString]) {
            return true;
        }
    }
    return false;
}

- (void)showDebugInfoView:(BOOL)show {
    _showDebugAlertView = show;
}

- (void)flushByType:(NSString *)type withSize:(int)flushSize andFlushMethod:(BOOL (^)(NSArray *, NSString *))flushMethod {
    while (true) {
        NSArray *recordArray = [self.messageQueue getFirstRecords:flushSize withType:type];
        if (recordArray == nil) {
            SAError(@"Failed to get records from SQLite.");
            break;
        }
        
        if ([recordArray count] == 0 || !flushMethod(recordArray, type)) {
            break;
        }
        
        if (![self.messageQueue removeFirstRecords:recordArray.count withType:type]) {
            SAError(@"Failed to remove records from SQLite.");
            break;
        }
    }
}

- (void)_flush:(BOOL) vacuumAfterFlushing {
    if (_serverURL == nil || [_serverURL isEqualToString:@""]) {
        return;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
    if (!([self toNetworkType:networkType] & _networkTypePolicy)) {
        return;
    }
    // 使用 Post 发送数据
    BOOL (^flushByPost)(NSArray *, NSString *) = ^(NSArray *recordArray, NSString *type) {
        NSString *jsonString;
        NSData *zippedData;
        NSString *b64String;
        NSString *postBody;
        @try {
            // 1. 先完成这一系列Json字符串的拼接
            jsonString = [NSString stringWithFormat:@"[%@]", [recordArray componentsJoinedByString:@","]];
            // 2. 使用gzip进行压缩
            zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
            // 3. base64
            b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            int hashCode = [b64String sensorsdata_hashCode];
            b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                      (CFStringRef)b64String,
                                                                                      NULL,
                                                                                      CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                      kCFStringEncodingUTF8));

            postBody = [NSString stringWithFormat:@"crc=%d&gzip=1&data_list=%@", hashCode, b64String];
        } @catch (NSException *exception) {
            SAError(@"%@ flushByPost format data error: %@", self, exception);
            return YES;
        }

        NSURL *url = [NSURL URLWithString:self.serverURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.timeoutInterval = 30;
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        // 普通事件请求，使用标准 UserAgent
        [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
        if (self->_debugMode == SensorsAnalyticsDebugOnly) {
            [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
        }

        //Cookie
        [request setValue:[[SensorsAnalyticsSDK sharedInstance] getCookieWithDecode:NO] forHTTPHeaderField:@"Cookie"];

        dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);
        __block BOOL flushSucc = YES;

        void (^block)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
                SAError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
                flushSucc = NO;
                dispatch_semaphore_signal(flushSem);
                return;
            }

            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
            NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
            NSString *messageDesc = nil;
            NSInteger statusCode = urlResponse.statusCode;
            if(statusCode != 200) {
                messageDesc = @"\n【invalid message】\n";
                if (self->_debugMode != SensorsAnalyticsDebugOff) {
                    if (statusCode >= 300) {
                        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                    }
                } else {
                    if (statusCode >= 300) {
                        flushSucc = NO;
                    }
                }
            } else {
                messageDesc = @"\n【valid message】\n";
            }
            SAError(@"==========================================================================");
            if ([SALogger isLoggerEnabled]) {
                @try {
                    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                    NSString *logString=[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
                    SAError(@"%@ %@: %@", self, messageDesc, logString);
                } @catch (NSException *exception) {
                    SAError(@"%@: %@", self, exception);
                }
            }
            if (statusCode != 200) {
                SAError(@"%@ ret_code: %ld", self, statusCode);
                SAError(@"%@ ret_content: %@", self, urlResponseContent);
            }

            dispatch_semaphore_signal(flushSem);
        };

        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:block];
        [task resume];

        dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);

        return flushSucc;
    };
    
    [self flushByType:@"Post" withSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1) andFlushMethod:flushByPost];

    if (vacuumAfterFlushing) {
        if (![self.messageQueue vacuum]) {
            SAError(@"failed to VACUUM SQLite.");
        }
    }

    SADebug(@"events flushed.");
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self _flush:NO];
    });
}

- (void)deleteAll {
    [self.messageQueue deleteAll];
}
#pragma mark - HandleURL
- (BOOL)canHandleURL:(NSURL *)url {
   return [[SAAuxiliaryToolManager sharedInstance] canHandleURL:url];
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
        
        if ([[SAAuxiliaryToolManager sharedInstance] isVisualizedAutoTrackURL:url] || [[SAAuxiliaryToolManager sharedInstance] isHeatMapURL:url]) {//点击图
            
            return [self handleAutoTrackURL:url];
        } else if ([[SAAuxiliaryToolManager sharedInstance] isDebugModeURL:url]) {//动态 debug 配置
            
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            // url query 解析
            NSMutableDictionary *paramDic = [NSMutableDictionary dictionaryWithDictionary:[SAServerUrl analysisQueryItemWithURLComponent:urlComponents]];

            //如果没传 info_id，视为伪造二维码，不做处理
            if (paramDic.allKeys.count &&  [paramDic.allKeys containsObject:@"info_id"]) {
                [self showDebugModeAlertWithParams:paramDic];
                return YES;
            } else {
                return NO;
            }
        }
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
    }
    return NO;
}

#pragma mark - VisualizedAutoTrack
- (void)enableVisualizedAutoTrack {
    _shouldVisualizedAutoTrack = YES;
}

- (BOOL)isVisualizedAutoTrackEnabled {
    return _shouldVisualizedAutoTrack;
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

    if (_visualizedAutoTrackViewControllers.count == 0) {
        return YES;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [_visualizedAutoTrackViewControllers containsObject:screenName];
}

#pragma mark - Heat Map
- (void)enableHeatMap {
    _shouldHeatMap = YES;
}

- (BOOL)isHeatMapEnabled {
    return _shouldHeatMap;
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

    if (_heatMapViewControllers.count == 0) {
        return YES;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [_heatMapViewControllers containsObject:screenName];
}

#pragma mark - track event

- (BOOL) isValidName : (NSString *) name {
    @try {
        if (_deviceModel == nil) {
            _deviceModel = [self deviceModel];
        }

        if (_osVersion == nil) {
            UIDevice *device = [UIDevice currentDevice];
            _osVersion = [device systemVersion];
        }

        //据反馈，该函数在 iPhone 8、iPhone 8 Plus，并且系统版本号为 11.0 上可能会 crash，具体原因暂未查明
        if ([_osVersion isEqualToString:@"11.0"]) {
            if ([_deviceModel isEqualToString:@"iPhone10,1"] ||
                [_deviceModel isEqualToString:@"iPhone10,4"] ||
                [_deviceModel isEqualToString:@"iPhone10,2"] ||
                [_deviceModel isEqualToString:@"iPhone10,5"]) {
                    return YES;
            }
        }
        return [self.regexTestName evaluateWithObject:name];
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
        return NO;
    }
}

- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", data];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    SADebug(@"filepath for %@ is %@", data, filepath);
    return filepath;
}

- (NSDictionary<NSString *, id> *)willEnqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    if (!self.trackEventCallback) {
        return [e copy];
    }
    NSMutableDictionary *event = [e mutableCopy];
    
    NSDictionary<NSString *, id> *originProperties = event[@"properties"];
    // can only modify "$device_id"
    NSArray *modifyKeys = @[@"$device_id"];
    BOOL(^canModifyPropertyKeys)(NSString *key) = ^BOOL(NSString *key) {
        return (![key hasPrefix:@"$"] || [modifyKeys containsObject:key]);
    };
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 添加可修改的事件属性
    [originProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (canModifyPropertyKeys(key)) {
            properties[key] = obj;
        }
    }];
    BOOL isIncluded = self.trackEventCallback(event[@"event"], properties);
    if (!isIncluded) {
        SALog(@"\n【track event】: %@ can not enter database.", event[@"event"]);
        return nil;
    }
    // 校验 properties
    if (![self assertPropertyTypes:&properties withEventType:type]) {
        SAError(@"%@ failed to track event.", self);
        return nil;
    }
    // assert 可能修改 properties 的类型
    properties = [properties mutableCopy];
    // 添加不可修改的事件属性，得到修改之后的所有属性
    [originProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (!canModifyPropertyKeys(key)) {
            properties[key] = obj;
        }
    }];
    // 对 properties 重新赋值
    event[@"properties"] = properties;

    return event;
}

- (void)enqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    [self.messageQueue addObejct:e withType:@"Post"];
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
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return;
        }
        if (![self isValidName:event]) {
            NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
            SAError(@"%@", errMsg);
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
            SAError(@"%@ failed to track event.", self);
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
        if ([event isEqualToString:SA_EVENT_NAME_APP_CLICK]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
                lib_detail = [NSString stringWithFormat:@"%@######", [propertieDict objectForKey:SA_EVENT_PROPERTY_SCREEN_NAME]];
            }
        } else if ([event isEqualToString:SA_EVENT_NAME_APP_VIEW_SCREEN]) {
            if ([self isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppViewScreen] == NO) {
                lib_detail = [NSString stringWithFormat:@"%@######", [propertieDict objectForKey:SA_EVENT_PROPERTY_SCREEN_NAME]];
            }
        }
    }

    if (lib_detail) {
        [libProperties setValue:lib_detail forKey:SA_EVENT_COMMON_PROPERTY_LIB_DETAIL];
    }
    __block NSDictionary *dynamicSuperPropertiesDict = self.dynamicSuperProperties?self.dynamicSuperProperties():nil;
    dispatch_async(self.serialQueue, ^{
        //获取用户自定义的动态公共属性
        if (dynamicSuperPropertiesDict && [dynamicSuperPropertiesDict isKindOfClass:NSDictionary.class] == NO) {
            SALog(@"dynamicSuperProperties  returned: %@  is not an NSDictionary Obj.", dynamicSuperPropertiesDict);
            dynamicSuperPropertiesDict = nil;
        } else {
            if ([self assertPropertyTypes:&dynamicSuperPropertiesDict withEventType:@"register_super_properties"] == NO) {
                dynamicSuperPropertiesDict = nil;
            }
        }
        //去重
        [self unregisterSameLetterSuperProperties:dynamicSuperPropertiesDict];

        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
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

            NSDictionary *eventTimer = self.trackTimer[event];
            if (eventTimer) {
                [self.trackTimer removeObjectForKey:event];
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];

                float eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue];
                }

                if (eventDuration < 0) {
                    eventDuration = 0;
                }

                if (eventDuration > 0 && eventDuration < 24 * 60 * 60 * 1000) {
                    switch (timeUnit) {
                        case SensorsAnalyticsTimeUnitHours:
                            eventDuration = eventDuration / 60.0;
                        case SensorsAnalyticsTimeUnitMinutes:
                            eventDuration = eventDuration / 60.0;
                        case SensorsAnalyticsTimeUnitSeconds:
                            eventDuration = eventDuration / 1000.0;
                        case SensorsAnalyticsTimeUnitMilliseconds:
                            break;
                    }
                    @try {
                        [p setObject:@([[NSString stringWithFormat:@"%.3f", eventDuration] floatValue]) forKey:@"event_duration"];
                    } @catch (NSException *exception) {
                        SAError(@"%@: %@", self, exception);
                    }
                }
            }
        }

        NSString *project = nil;
        NSString *token = nil;
        if (propertieDict) {
            NSArray *keys = propertieDict.allKeys;
            for (id key in keys) {
                NSObject *obj = propertieDict[key];
                if ([SA_EVENT_COMMON_OPTIONAL_PROPERTY_PROJECT isEqualToString:key]) {
                    project = (NSString *)obj;
                } else if ([SA_EVENT_COMMON_OPTIONAL_PROPERTY_TOKEN isEqualToString:key]) {
                    token = (NSString *)obj;
                } else {
                    if ([obj isKindOfClass:[NSDate class]]) {
                        // 序列化所有 NSDate 类型
                        NSString *dateStr = [self->_dateFormatter stringFromDate:(NSDate *)obj];
                        [p setObject:dateStr forKey:key];
                    } else {
                        [p setObject:obj forKey:key];
                    }
                }
            }
        }

        NSMutableDictionary *e;
        NSString *bestId = self.getBestId;

        if ([type isEqualToString:@"track_signup"]) {
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 event, SA_EVENT_NAME,
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
                SAError(@"%@: %@", self, e);
            }

#ifndef SENSORS_ANALYTICS_DISABLE_TRACK_DEVICE_ORIENTATION
            @try {
                //采集设备方向
                if (self.deviceOrientationConfig.enableTrackScreenOrientation && self.deviceOrientationConfig.deviceOrientation.length) {
                    [p setObject:self.deviceOrientationConfig.deviceOrientation forKey:SA_EVENT_COMMON_OPTIONAL_PROPERTY_SCREEN_ORIENTATION];
                }
            } @catch (NSException *e) {
                SAError(@"%@: %@", self, e);
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
                SAError(@"%@: %@", self, e);
            }
#endif
            e = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 event, SA_EVENT_NAME,
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
        SALog(@"\n【track event】:\n%@", eventDic);

        [self enqueueWithType:type andEvent:eventDic];

        if (self->_debugMode != SensorsAnalyticsDebugOff) {
            // 在DEBUG模式下，直接发送事件
            [self flush];
        } else {
            // 否则，在满足发送条件时，发送事件
            if ([type isEqualToString:@"track_signup"] || [[self messageQueue] count] >= self.flushBulkSize) {
                [self flush];
            }
        }
    });
}

- (NSString *)getBestId {
    NSString *bestId;
    if ([self loginId] != nil) {
        bestId = [self loginId];
    } else {
        bestId = [self distinctId];
    }

    if (bestId == nil) {
        [self resetAnonymousId];
        bestId = [self anonymousId];
    }
    return bestId;
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil withTrackType:SensorsAnalyticsTrackTypeCode];;
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    [self track:event withProperties:propertieDict withTrackType:SensorsAnalyticsTrackTypeCode];
}

- (void)track:(NSString *)event withTrackType:(SensorsAnalyticsTrackType)trackType {
    [self track:event withProperties:nil withTrackType:trackType];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withTrackType:(SensorsAnalyticsTrackType)trackType {
    if (trackType == SensorsAnalyticsTrackTypeCode) {
        //事件校验，预置事件提醒
        if ([self.regexEventName evaluateWithObject:event]) {
            SAError(@"\n【event warning】\n %@ is a preset event name of us, it is recommended that you use a new one", event);
        };
        
        [self track:event withProperties:propertieDict withType:@"codeTrack"];
    } else {
        [self track:event withProperties:propertieDict withType:@"track"];
    }
}

- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    if (encode) {
        _cookie = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                (CFStringRef)cookie,
                                                                                NULL,
                                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                kCFStringEncodingUTF8));
    } else {
        _cookie = cookie;
    }
}

- (NSString *)getCookieWithDecode:(BOOL)decode {
    if (decode) {
        return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)_cookie, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    } else {
        return _cookie;
    }
}

- (void)trackTimer:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitMilliseconds];
}

- (void)trackTimerStart:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
}

- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    if (![self isValidName:event]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
        SAError(@"%@", errMsg);
        if (_debugMode != SensorsAnalyticsDebugOff) {
            [self showDebugModeWarning:errMsg withNoMoreButton:YES];
        }
        return;
    }
    
    NSNumber *eventBegin = @([[self class] getSystemUpTime]);
    dispatch_async(self.serialQueue, ^{
        self.trackTimer[event] = @{@"eventBegin" : eventBegin, @"eventAccumulatedDuration" : [NSNumber numberWithLong:0], @"timeUnit" : [NSNumber numberWithInt:timeUnit]};
    });
}

- (void)trackTimerEnd:(NSString *)event {
    [self track:event withTrackType:SensorsAnalyticsTrackTypeAuto];
}

- (void)trackTimerEnd:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self track:event withProperties:propertyDict withTrackType:SensorsAnalyticsTrackTypeAuto];
}

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        self.trackTimer = [NSMutableDictionary dictionary];
    });
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict disableCallback:(BOOL)disableCallback {
    BOOL hasTrackInstallation = NO;
    NSString *userDefaultsKey = nil;
    userDefaultsKey = disableCallback?SA_HAS_TRACK_INSTALLATION_DISABLE_CALLBACK:SA_HAS_TRACK_INSTALLATION;
    
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
#ifndef SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN
    hasTrackInstallation = disableCallback?[SAKeyChainItemWrapper hasTrackInstallationWithDisableCallback]:[SAKeyChainItemWrapper hasTrackInstallation];
    if (hasTrackInstallation) {
        return;
    }
#endif
#endif

    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:userDefaultsKey]) {
        hasTrackInstallation = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:userDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        hasTrackInstallation = YES;
    }
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
#ifndef SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN
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

        NSString *userAgent = [propertyDict objectForKey:SA_EVENT_PROPERTY_APP_INSTALL_USER_AGENT];
        if (userAgent ==nil || userAgent.length == 0) {
            userAgent = self.class.getUserAgent;
        }
        if (userAgent) {
            [properties setValue:userAgent forKey:SA_EVENT_PROPERTY_APP_INSTALL_USER_AGENT];
        }

        if (propertyDict != nil) {
            [properties addEntriesFromDictionary:propertyDict];
        }

        // 先发送 track
        [self track:event withProperties:properties withType:@"track"];

        // 再发送 profile_set_once
        NSMutableDictionary *profileProperties = [properties mutableCopy];
        [profileProperties setValue:[NSDate date] forKey:SA_EVENT_PROPERTY_APP_INSTALL_FIRST_VISIT_TIME];
        [self track:nil withProperties:profileProperties withType:SA_PROFILE_SET_ONCE];

        [self flush];
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
        SADebug(@"%@: %@", self, exception);
        return idfa;
    }
}

- (void)ignoreAutoTrackViewControllers:(NSArray *)controllers {
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

- (void)identify:(NSString *)distinctId {
    if (distinctId.length == 0) {
        SAError(@"%@ cannot identify blank distinct id: %@", self, distinctId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics distinct_id should not be nil or empty" userInfo:nil];
        return;
    }
    if (distinctId.length > 255) {
        SAError(@"%@ max length of distinct_id is 255, distinct_id: %@", self, distinctId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics max length of distinct_id is 255" userInfo:nil];
    }
    dispatch_async(self.serialQueue, ^{
        // 先把之前的distinctId设为originalId
        self.originalId = self.distinctId;
        // 更新distinctId
        self.distinctId = distinctId;
        [self archiveDistinctId];
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
            SAError(@"%@", errMsg);
            if (_debugMode != SensorsAnalyticsDebugOff) {
                [self showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
            return NO;
        }

        // key的名称必须符合要求
        if (![self isValidName: k]) {
            NSString *errMsg = [NSString stringWithFormat:@"property name[%@] is not valid", k];
            SAError(@"%@", errMsg);
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
            SAError(@"%@", errMsg);
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

        // NSSet、NSArray 类型的属性中，每个元素必须是 NSString 类型
        if ([propertyValue isKindOfClass:[NSSet class]] || [propertyValue isKindOfClass:[NSArray class]]) {
            NSEnumerator *enumerator = [propertyValue objectEnumerator];
            id object;
            while (object = [enumerator nextObject]) {
                if (![object isKindOfClass:[NSString class]]) {
                    NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet、NSArray must be NSString. got: %@ %@", self, [object class], object];
                    SAError(@"%@", errMsg);
                    if (_debugMode != SensorsAnalyticsDebugOff) {
                        [self showDebugModeWarning:errMsg withNoMoreButton:YES];
                    }
                    return NO;
                }
                NSUInteger objLength = [((NSString *)object) lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                if (objLength > SA_PROPERTY_LENGTH_LIMITATION) {
                    //截取再拼接 $ 末尾，替换原数据
                    NSMutableString *newObject = [NSMutableString stringWithString:[SACommonUtility subByteString:(NSString *)object byteLength:SA_PROPERTY_LENGTH_LIMITATION - 1]];
                    [newObject appendString:@"$"];
                    if (!newProperties) {
                        newProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
                    }

                    NSMutableSet *newSetObject = nil;
                    if ([propertyValue isKindOfClass:[NSArray class]]) {
                        newSetObject = [NSMutableSet setWithArray:propertyValue];
                    } else {
                        newSetObject = [NSMutableSet setWithSet:propertyValue];
                    }
                    [newSetObject removeObject:object];
                    [newSetObject addObject:newObject];
                    [newProperties setObject:newSetObject forKey:k];
                }
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
                SAError(@"%@", errMsg);
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
                SAError(@"%@", errMsg);
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
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    _deviceModel = [self deviceModel];
    _osVersion = [device systemVersion];
    struct CGSize size = [UIScreen mainScreen].bounds.size;
    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nil;
    
    if (@available(iOS 12.0, *)) {
        carrier = telephonyInfo.serviceSubscriberCellularProviders.allValues.lastObject;
    } else {
        carrier = telephonyInfo.subscriberCellularProvider;
    }

    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:SA_EVENT_COMMON_PROPERTY_APP_VERSION];
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
        } else { //国外运营商解析
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
            [p setValue:carrierName forKey:SA_EVENT_COMMON_PROPERTY_CARRIER];
        } else {
            if (carrier.carrierName) {
                [p setValue:carrier.carrierName forKey:SA_EVENT_COMMON_PROPERTY_CARRIER];
            }
        }
    }
    
#if !SENSORS_ANALYTICS_DISABLE_AUTOTRACK_DEVICEID
    [p setValue:[[self class] getUniqueHardwareId] forKey:SA_EVENT_COMMON_PROPERTY_DEVICE_ID];
#endif
    [p addEntriesFromDictionary:@{
                                  SA_EVENT_COMMON_PROPERTY_LIB: @"iOS",
                                  SA_EVENT_COMMON_PROPERTY_LIB_VERSION: [self libVersion],
                                  SA_EVENT_COMMON_PROPERTY_MANUFACTURER: @"Apple",
                                  SA_EVENT_COMMON_PROPERTY_OS: @"iOS",
                                  SA_EVENT_COMMON_PROPERTY_OS_VERSION: _osVersion,
                                  SA_EVENT_COMMON_PROPERTY_MODEL: _deviceModel,
                                  SA_EVENT_COMMON_PROPERTY_SCREEN_HEIGHT: @((NSInteger)size.height),
                                  SA_EVENT_COMMON_PROPERTY_SCREEN_WIDTH: @((NSInteger)size.width),
                                      }];
    return [p copy];
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    propertyDict = [propertyDict copy];
    if (![self assertPropertyTypes:&propertyDict withEventType:@"register_super_properties"]) {
        SAError(@"%@ failed to register super properties.", self);
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
    SALog(@"SDK have set trackEvent callBack");
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
    [self unarchiveDistinctId];
    [self unarchiveLoginId];
    [self unarchiveSuperProperties];
    [self unarchiveFirstDay];
}

- (id)unarchiveFromFile:(NSString *)filePath {
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        SAError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    return unarchivedData;
}

- (void)unarchiveDistinctId {
    NSString *filePath = [self filePathForData:SA_EVENT_DISTINCT_ID];
    NSString *archivedDistinctId = (NSString *)[self unarchiveFromFile:filePath];

#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    NSString *distinctIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain != nil && distinctIdInKeychain.length > 0) {
        self.distinctId = distinctIdInKeychain;
        if (![archivedDistinctId isEqualToString:distinctIdInKeychain]) {
            //保存 Archiver
            NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
            [[NSFileManager defaultManager] setAttributes:protection ofItemAtPath:filePath error:nil];
            if (![NSKeyedArchiver archiveRootObject:[[self distinctId] copy] toFile:filePath]) {
                SAError(@"%@ unable to archive distinctId", self);
            }
        }
    } else {
#endif
        if (archivedDistinctId.length == 0) {
            self.distinctId = [[self class] getUniqueHardwareId];
            [self archiveDistinctId];
        } else {
            self.distinctId = archivedDistinctId;
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
            //保存 KeyChain
            [SAKeyChainItemWrapper saveUdid:self.distinctId];
        }
#endif
    }
}

- (void)unarchiveLoginId {
    NSString *archivedLoginId = (NSString *)[self unarchiveFromFile:[self filePathForData:@"login_id"]];
    self.loginId = archivedLoginId;
}

- (void)unarchiveFirstDay {
    NSString *archivedFirstDay = (NSString *)[self unarchiveFromFile:[self filePathForData:@"first_day"]];
    self.firstDay = archivedFirstDay;
}

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = (NSDictionary *)[self unarchiveFromFile:[self filePathForData:@"super_properties"]];
    if (archivedSuperProperties == nil) {
        _superProperties = [NSDictionary dictionary];
    } else {
        _superProperties = [archivedSuperProperties copy];
    }
}

- (void)archiveDistinctId {
    NSString *filePath = [self filePathForData:SA_EVENT_DISTINCT_ID];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self distinctId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive distinctId", self);
    }
#ifndef SENSORS_ANALYTICS_DISABLE_KEYCHAIN
    [SAKeyChainItemWrapper saveUdid:self.distinctId];
#endif
    SADebug(@"%@ archived distinctId", self);
}

- (void)archiveLoginId {
    NSString *filePath = [self filePathForData:@"login_id"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self loginId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive loginId", self);
    }
    SADebug(@"%@ archived loginId", self);
}

- (void)archiveFirstDay {
    NSString *filePath = [self filePathForData:@"first_day"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[[self firstDay] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive firstDay", self);
    }
    SADebug(@"%@ archived firstDay", self);
}

- (void)archiveSuperProperties {
    NSString *filePath = [self filePathForData:@"super_properties"];
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    if (![NSKeyedArchiver archiveRootObject:[self.superProperties copy] toFile:filePath]) {
        SAError(@"%@ unable to archive super properties", self);
    }
    SADebug(@"%@ archive super properties data", self);
}

#pragma mark - Network control

+ (NSString *)getNetWorkStates {
#ifdef SA_UT
    SADebug(@"In unit test, set NetWorkStates to wifi");
    return @"WIFI";
#endif
    NSString* network = @"NULL";
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
            if (@available(iOS 12.0, *)) {
                currentRadioAccessTechnology = netinfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
            } else {
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
            } else if (currentRadioAccessTechnology) {
                network = @"UNKNOWN";
            }
            
        }
    } @catch(NSException *exception) {
        SADebug(@"%@: %@", self, exception);
    }
    return network;
}

- (UInt64)flushInterval {
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(UInt64)interval {
    @synchronized(self) {
        if (interval < 5 * 1000) {
            interval = 5 * 1000;
        }
        _flushInterval = interval;
    }
    [self flush];
    [self startFlushTimer];
}

- (void)startFlushTimer {
    [self stopFlushTimer];
    if (self.remoteConfig.disableSDK) {
        return;
    }
    SADebug(@"starting flush timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_flushInterval > 0) {
            double interval = self->_flushInterval > 100 ? (double)self->_flushInterval / 1000.0 : 0.1f;
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

- (UInt64)flushBulkSize {
    @synchronized(self) {
        return _flushBulkSize;
    }
}

- (void)setFlushBulkSize:(UInt64)bulkSize {
    @synchronized(self) {
        //加上最小值保护，50
        _flushBulkSize = bulkSize >= 50 ? bulkSize : 50;
    }
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

- (void)addWebViewUserAgentSensorsDataFlag {
    [self addWebViewUserAgentSensorsDataFlag:YES];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify  {
    [self addWebViewUserAgentSensorsDataFlag:enableVerify userAgent:nil];
}

- (void)addWebViewUserAgentSensorsDataFlag:(BOOL)enableVerify userAgent:(nullable NSString *)userAgent{
    [NSThread sa_safelyRunOnMainThreadSync:^{
        BOOL verify = enableVerify;
        @try {
            if (self->_serverURL == nil || self->_serverURL.length == 0) {
                verify = NO;
            }
            SAServerUrl *ss = [[SAServerUrl alloc] initWithUrl:self->_serverURL];
            NSString *oldAgent = nil;
            if (userAgent && userAgent.length) {
                oldAgent = userAgent;
            } else {
                oldAgent = self.class.getUserAgent;
            }
            NSString *newAgent = oldAgent;
            if ([oldAgent rangeOfString:@"sa-sdk-ios"].location == NSNotFound) {
                if (verify) {
                    newAgent = [oldAgent stringByAppendingString:[NSString stringWithFormat: @" /sa-sdk-ios/sensors-verify/%@?%@ ", ss.host, ss.project]];
                } else {
                    newAgent = [oldAgent stringByAppendingString:@" /sa-sdk-ios"];
                }
            }
            //使 newAgent 生效，并设置 _userAgent
            NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
            [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
            self->_userAgent = newAgent;
            [[NSUserDefaults standardUserDefaults] synchronize];
        } @catch (NSException *exception) {
            SADebug(@"%@: %@", self, exception);
        }
    }
     ];
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

        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }

        //忽略 $AppClick 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }

        if ([self isViewTypeIgnored:[view class]]) {
            return;
        }

        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }

        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

        UIViewController *viewController = [self currentViewController];
        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }

            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];
            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle) {
                [properties setValue:controllerTitle forKey:SA_EVENT_PROPERTY_TITLE];
            }
        }

        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:SA_EVENT_PROPERTY_ELEMENT_ID];
        }

        [properties setValue:NSStringFromClass([view class]) forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];

        NSString *elementContent = [AutoTrackUtils contentFromView:view];
        if (elementContent.length > 0) {
            [properties setValue:elementContent forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
        }

        if (p != nil) {
            [properties addEntriesFromDictionary:p];
        }

        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }

        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
    } @catch (NSException *exception) {
        SAError(@"%@: %@", self, exception);
    }
}

#pragma mark - UIApplication Events

- (void)setUpListeners {
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
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
    NSString *screenName = NSStringFromClass(controller.class);
    //过滤用户设置的不被AutoTrack的Controllers
    if (_ignoredViewControllers.count > 0 && screenName) {
        if ([_ignoredViewControllers containsObject:screenName]) {
            return;
        }
    }
    
    if (self.launchedPassively) {
        if (controller) {
            if (!self.launchedPassivelyControllers) {
                self.launchedPassivelyControllers = [NSMutableArray array];
            }
            
            if ([self shouldTrackViewScreen:controller]) {
                [self.launchedPassivelyControllers addObject:controller];
            }
        }
        return;
    }
    
    [self trackViewScreen:controller];
}

- (void)trackViewScreen:(UIViewController *)controller {
    [self trackViewScreen:controller properties:nil];
}

- (void)trackViewScreen:(UIViewController *)controller properties:(nullable NSDictionary<NSString *, id> *)properties_ {
    if (!controller) {
        return;
    }
    
    if (![self shouldTrackViewScreen:controller]) {
        return;
    }

    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    NSString *screenName = NSStringFromClass(controller.class);
    [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];

    @try {
        NSString *controllerTitle = [AutoTrackUtils titleFromViewController:controller];
        if (controllerTitle) {
            [properties setValue:controllerTitle forKey:SA_EVENT_PROPERTY_TITLE];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ failed to get UIViewController's title error: %@", self, exception);
    }

    if ([controller conformsToProtocol:@protocol(SAAutoTracker)] && [controller respondsToSelector:@selector(getTrackProperties)]) {
        UIViewController<SAAutoTracker> *autoTrackerController = (UIViewController<SAAutoTracker> *)controller;
        _lastScreenTrackProperties = [autoTrackerController getTrackProperties];
        [properties addEntriesFromDictionary:_lastScreenTrackProperties];
    }

#ifdef SENSORS_ANALYTICS_AUTOTRACT_APPVIEWSCREEN_URL
    [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_URL];
    @synchronized(_referrerScreenUrl) {
        if (_referrerScreenUrl) {
            [properties setValue:_referrerScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_REFERRER_URL];
        }
        _referrerScreenUrl = screenName;
    }
#endif

    if ([controller conformsToProtocol:@protocol(SAScreenAutoTracker)] && [controller respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)controller;
        NSString *currentScreenUrl = [screenAutoTrackerController getScreenUrl];
        
        [properties setValue:currentScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_URL];

        @synchronized(_referrerScreenUrl) {
            if (_referrerScreenUrl) {
                [properties setValue:_referrerScreenUrl forKey:SA_EVENT_PROPERTY_SCREEN_REFERRER_URL];
            }
            _referrerScreenUrl = currentScreenUrl;
        }
    }
    [properties addEntriesFromDictionary:properties_];
    [self track:SA_EVENT_NAME_APP_VIEW_SCREEN withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
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
        SAError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
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
                }

                [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", [SensorsAnalyticsSDK sharedInstance], exception);
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
        [UIViewController sa_swizzleMethod:@selector(viewWillAppear:) withMethod:@selector(sa_autotrack_viewWillAppear:) error:NULL];
        NSError *error = NULL;
        //$AppClick
        // Actions & Events
        [UIApplication sa_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                             withMethod:@selector(sa_sendAction:to:from:forEvent:)
                                  error:&error];
        if (error) {
            SAError(@"Failed to swizzle sendAction:to:forEvent: on UIAppplication. Details: %@", error);
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
            SAError(@"Failed to swizzle Target on UITapGestureRecognizer. Details: %@", error);
            error = NULL;
        }
    });
#endif
    
    //React Natove
#ifdef SENSORS_ANALYTICS_REACT_NATIVE
    if (NSClassFromString(@"RCTUIManager")) {
        //        [SASwizzler swizzleSelector:NSSelectorFromString(@"setJSResponder:blockNativeResponder:") onClass:NSClassFromString(@"RCTUIManager") withBlock:reactNativeAutoTrackBlock named:@"track_React_Native_AppClick"];
        sa_methodExchange("RCTUIManager", "setJSResponder:blockNativeResponder:", "sda_setJSResponder:blockNativeResponder:", (IMP)sa_imp_setJSResponderBlockNativeResponder);
    }
#endif
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
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    SADebug(@"%@ application will enter foreground", self);
    
    _appRelaunched = YES;
    self.launchedPassively = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SADebug(@"%@ application did become active", self);
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
    
    [self requestFunctionalManagermentConfig];
    if (_applicationWillResignActive) {
        _applicationWillResignActive = NO;
        if (self.timer == nil || ![self.timer isValid]) {
            [self startFlushTimer];
        }
        return;
    }
    _applicationWillResignActive = NO;

    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SA_HAS_LAUNCHED_ONCE]) {
        isFirstStart = YES;
    }

    // 遍历 trackTimer ,修改 eventBegin 为当前 currentSystemUpTime
    dispatch_async(self.serialQueue, ^{

        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                [eventTimer setValue:currentSystemUpTime forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }
    });

    if ([self isAutoTrackEnabled] && _appRelaunched) {
        // 追踪 AppStart 事件
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart] == NO) {
            [self track:SA_EVENT_NAME_APP_START withProperties:@{
                                                         SA_EVENT_PROPERTY_RESUME_FROM_BACKGROUND : @(_appRelaunched),
                                                         SA_EVENT_PROPERTY_APP_FIRST_START : @(isFirstStart),
                                                         } withTrackType:SensorsAnalyticsTrackTypeAuto];
        }
        // 启动 AppEnd 事件计时器
        if ([self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd] == NO) {
            [self trackTimer:SA_EVENT_NAME_APP_END withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
        }
    }
    
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
    SADebug(@"%@ application will resign active", self);
    _applicationWillResignActive = YES;
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SADebug(@"%@ application did enter background", self);
    _applicationWillResignActive = NO;
    self.launchedPassively = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestFunctionalManagermentConfigWithCompletion:) object:self.reqConfigBlock];
    
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
    // eventAccumulatedDuration = eventAccumulatedDuration + currentSystemUpTime - eventBegin
    dispatch_async(self.serialQueue, ^{
        NSNumber *currentSystemUpTime = @([[self class] getSystemUpTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            if (key != nil) {
                if ([key isEqualToString:SA_EVENT_NAME_APP_END]) {
                    continue;
                }
            }
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                long eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [currentSystemUpTime longValue] - [eventBegin longValue];
                }
                [eventTimer setObject:[NSNumber numberWithLong:eventDuration] forKey:@"eventAccumulatedDuration"];
                [eventTimer setObject:currentSystemUpTime forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }
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
    SALog(@"applicationWillTerminateNotification");
    dispatch_sync(self.serialQueue, ^{
    });
}

#pragma mark - SensorsData  Analytics

- (void)set:(NSDictionary *)profileDict {
    [[self people] set:profileDict];
}

- (void)profilePushKey:(NSString *)pushKey pushId:(NSString *)pushId {
    if ([pushKey isKindOfClass:NSString.class] && pushKey.length && [pushId isKindOfClass:NSString.class] && pushId.length) {
        NSString * distinctId = self.getBestId;
        NSString * keyOfPushId = [NSString stringWithFormat:@"sa_%@_%@", distinctId, pushKey];
        NSString * valueOfPushId = [NSUserDefaults.standardUserDefaults valueForKey:keyOfPushId];
        NSString * newValueOfPushId = [NSString stringWithFormat:@"%@_%@", distinctId, pushId];
        if (![valueOfPushId isEqualToString:newValueOfPushId]) {
            [self set:@{pushKey:pushId}];
            [NSUserDefaults.standardUserDefaults setValue:newValueOfPushId forKey:keyOfPushId];
        }
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
    [SALogger enableLog:enabelLog];
}

- (void)enableLog {
    BOOL printLog = NO;
#if (defined SENSORS_ANALYTICS_ENABLE_LOG)
    printLog = YES;
#endif
    
    if ( [self debugMode] != SensorsAnalyticsDebugOff) {
        printLog = YES;
    }
    [SALogger enableLog:printLog];
}

- (void)setSDKWithRemoteConfigDict:(NSDictionary *)configDict {
    @try {
        self.remoteConfig = [SASDKRemoteConfig configWithDict:configDict];
        if (self.remoteConfig.disableDebugMode) {
            [self disableDebugMode];
        }
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
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

- (void)requestFunctionalManagermentConfig {
    @try {
        [self requestFunctionalManagermentConfigDelay:0 index:0];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
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
            SAError(@"%@ error: %@", self, e);
        }
    };
    @try {
        self.reqConfigBlock = block;
        [self performSelector:@selector(requestFunctionalManagermentConfigWithCompletion:) withObject:self.reqConfigBlock afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
    }
}

- (void)requestFunctionalManagermentConfigWithCompletion:(void(^)(BOOL success, NSDictionary*configDict )) completion{
    @try {
         NSString *networkTypeString = [SensorsAnalyticsSDK getNetWorkStates];
        SensorsAnalyticsNetworkType networkType = [self toNetworkType:networkTypeString];
        
        NSString *urlString = [self collectRemoteConfigUrl];
        if (urlString == nil || urlString.length == 0 || networkType == SensorsAnalyticsNetworkTypeNONE) {
            completion(NO,nil);
            return;
        }
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            @try {
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                if (statusCode == 200) {
                    NSError *err = NULL;
                    NSDictionary *dict = nil;
                    if (data !=nil && data.length ) {
                        dict = [NSJSONSerialization  JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
                    }
                    if (completion) {
                        completion(YES,dict);
                    }
                } else if (statusCode == 304) {
                    //304 config 没有更新
                    if (completion) {
                        completion(YES,nil);
                    }
                } else {
                    if (completion) {
                        completion(NO,nil);
                    }
                }
            } @catch (NSException *e) {
                SAError(@"%@ error: %@", self, e);
                if (completion) {
                    completion(NO,nil);
                }
            }
        }];
        [task resume];
    } @catch (NSException *e) {
        SAError(@"%@ error: %@", self, e);
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
        SAError(@"%@ error: %@", self, e);
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
                        SALog(@"enableTrackGPSLocation error：%@", error);
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

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    return [SensorsAnalyticsSDK sharedInstanceWithServerURL:serverURL
                                           andLaunchOptions:nil andDebugMode:debugMode];
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                    andLaunchOptions:(NSDictionary *)launchOptions
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithServerURL:serverURL
                                        andLaunchOptions:launchOptions
                                            andDebugMode:debugMode];
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(nonnull NSString *)serverURL
                                    andLaunchOptions:(NSDictionary * _Nullable)launchOptions {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithServerURL:serverURL
                                        andLaunchOptions:launchOptions
                                            andDebugMode:SensorsAnalyticsDebugOff];
    });
    return sharedInstance;
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    _debugMode = debugMode;
    [self enableLog];
    [self configDebugModeServerUrl];
}

- (void)enableAutoTrack {
    [self enableAutoTrack:SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppEnd | SensorsAnalyticsEventTypeAppViewScreen];
}
- (void)ignoreAutoTrackEventType:(SensorsAnalyticsAutoTrackEventType)eventType {
    _autoTrackEventType = _autoTrackEventType ^ eventType;
}

- (void)trackTimerBegin:(NSString *)event {
    [self trackTimer:event];
}

- (void)trackTimerBegin:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    [self trackTimer:event withTimeUnit:timeUnit];
}
- (void)trackSignUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertieDict {
    [self identify:newDistinctId];
    [self track:@"$SignUp" withProperties:propertieDict withType:@"track_signup"];
}

- (void)trackSignUp:(NSString *)newDistinctId {
    [self identify:newDistinctId];
    [self track:SA_EVENT_NAME_APP_SIGN_UP withProperties:nil withType:@"track_signup"];
}

- (BOOL)handleHeatMapUrl:(NSURL *)URL {
    return [self handleAutoTrackURL:URL];
}

@end
