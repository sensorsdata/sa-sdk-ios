//  SensorsAnalyticsSDK.m
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
//  Copyright (c) 2015年 SensorsData. All rights reserved.

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_1
#define supportsWKWebKit
#endif

#import <objc/runtime.h>
#include <sys/sysctl.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

#import "JSONUtil.h"
#import "LFCGzipUtility.h"
#import "MessageQueueBySqlite.h"
#import "NSData+SABase64.h"
#import "SADesignerConnection.h"
#import "SADesignerEventBindingMessage.h"
#import "SADesignerSessionCollection.h"
#import "SAEventBinding.h"
#import "SALogger.h"
#import "SAReachability.h"
#import "SASwizzler.h"
#import "SensorsAnalyticsSDK.h"
#import "JSONUtil.h"

#if defined(supportsWKWebKit)
#import <WebKit/WebKit.h>
#endif

#define VERSION @"1.6.32"

#define PROPERTY_LENGTH_LIMITATION 8191

// 自动追踪相关事件及属性
// App 启动或激活
NSString* const APP_START_EVENT = @"$AppStart";
// App 退出或进入后台
NSString* const APP_END_EVENT = @"$AppEnd";
// App 浏览页面
NSString* const APP_VIEW_SCREEN_EVENT = @"$AppViewScreen";
// App 首次启动
NSString* const APP_FIRST_START_PROPERTY = @"$is_first_time";
// App 是否从后台恢复
NSString* const RESUME_FROM_BACKGROUND_PROPERTY = @"$resume_from_background";
// App 浏览页面名称
NSString* const SCREEN_NAME_PROPERTY = @"$screen_name";
// App 浏览页面 Url
NSString* const SCREEN_URL_PROPERTY = @"$url";
// App 浏览页面 Referrer Url
NSString* const SCREEN_REFERRER_URL_PROPERTY = @"$referrer";
// App 推送相关:
NSString* const APP_PUSH_ID_PROPERTY_BAIDU = @"$app_push_id_baidu";
NSString* const APP_PUSH_ID_PROPERTY_JIGUANG = @"$app_push_id_jiguang";
NSString* const APP_PUSH_ID_PROPERTY_QQ = @"$app_push_id_qq";
NSString* const APP_PUSH_ID_PROPERTY_GETUI = @"$app_push_id_xiaomi";
NSString* const APP_PUSH_ID_PROPERTY_XIAOMI = @"$app_push_id_getui";

@implementation SensorsAnalyticsDebugException

@end

@interface SensorsAnalyticsSDK()

// 在内部，重新声明成可读写的
@property (atomic, strong) SensorsAnalyticsPeople *people;

@property (atomic, copy) NSString *serverURL;
@property (atomic, copy) NSString *configureURL;
@property (atomic, copy) NSString *vtrackServerURL;

@property (atomic, copy) NSString *distinctId;
@property (atomic, copy) NSString *originalId;
@property (atomic, copy) NSString *loginId;
@property (atomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *superProperties;
@property (nonatomic, strong) NSMutableDictionary *trackTimer;

@property (nonatomic, strong) NSPredicate *regexTestName;

@property (atomic, strong) MessageQueueBySqlite *messageQueue;

@property (nonatomic, strong) id abtestDesignerConnection;
@property (atomic, strong) NSSet *eventBindings;

@property (assign, nonatomic) BOOL safariRequestInProgress;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *vtrackConnectorTimer;

//用户设置的不被AutoTrack的Controllers
@property (nonatomic, strong) NSMutableArray *filterControllers;

// 用于 SafariViewController
@property (strong, nonatomic) UIWindow *secondWindow;

- (instancetype)initWithServerURL:(NSString *)serverURL
                  andConfigureURL:(NSString *)configureURL
               andVTrackServerURL:(NSString *)vtrackServerURL
                     andDebugMode:(SensorsAnalyticsDebugMode)debugMode;

@end

@implementation SensorsAnalyticsSDK {
    SensorsAnalyticsDebugMode _debugMode;
    UInt64 _flushBulkSize;
    UInt64 _flushInterval;
    UIWindow *_vtrackWindow;
    NSDateFormatter *_dateFormatter;
    BOOL _autoTrack;                    // 自动采集事件
    BOOL _appRelaunched;                // App 从后台恢复
    NSString *_referrerScreenUrl;
    NSDictionary *_lastScreenTrackProperties;
}

static SensorsAnalyticsSDK *sharedInstance = nil;

#pragma mark - Initialization

+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                     andConfigureURL:(NSString *)configureURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    return [SensorsAnalyticsSDK sharedInstanceWithServerURL:serverURL
                                            andConfigureURL:configureURL
                                         andVTrackServerURL:nil
                                               andDebugMode:debugMode];
}


+ (SensorsAnalyticsSDK *)sharedInstanceWithServerURL:(NSString *)serverURL
                                     andConfigureURL:(NSString *)configureURL
                                  andVTrackServerURL:(NSString *)vtrackServerURL
                                        andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithServerURL:serverURL
                                          andConfigureURL:configureURL
                                       andVTrackServerURL:vtrackServerURL
                                             andDebugMode:debugMode];
    });
    return sharedInstance;
}

+ (SensorsAnalyticsSDK *)sharedInstance {
    return sharedInstance;
}

+ (UInt64)getCurrentTime {
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    return time;
}

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal {
    NSString *distinctId = NULL;

    // 宏 SENSORS_ANALYTICS_IDFA 定义时，优先使用IDFA
#if defined(SENSORS_ANALYTICS_IDFA)
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        distinctId = [uuid UUIDString];
        // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
        // 00000000-0000-0000-0000-000000000000
        if (distinctId && ![distinctId hasPrefix:@"00000000"]) {
            *isReal = YES;
        } else{
            distinctId = NULL;
        }
    }
#endif
    
    // 没有IDFA，则使用IDFV
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
        *isReal = YES;
    }
    
    // 没有IDFV，则使用UUID
    if (!distinctId) {
        SADebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
        *isReal = NO;
    }
    
    return distinctId;
}

- (instancetype)initWithServerURL:(NSString *)serverURL
                  andConfigureURL:(NSString *)configureURL
               andVTrackServerURL:(NSString *)vtrackServerURL
                     andDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    if (serverURL == nil || [serverURL length] == 0) {
        if (_debugMode != SensorsAnalyticsDebugOff) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                       reason:@"serverURL is nil"
                                     userInfo:nil];
        } else {
            SAError(@"serverURL is nil");
        }
    }
    
    if (debugMode != SensorsAnalyticsDebugOff) {
        // 将 Server URI Path 替换成 Debug 模式的 '/debug'
        NSURL *url = [[[NSURL URLWithString:serverURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"debug"];
        serverURL = [url absoluteString];
    }
    
    // 将 Configure URI Path 末尾补齐 iOS.conf
    NSURL *url = [NSURL URLWithString:configureURL];
    if ([[url lastPathComponent] isEqualToString:@"config"]) {
        url = [url URLByAppendingPathComponent:@"iOS.conf"];
    }
    configureURL = [url absoluteString];
    
    if (self = [self init]) {
        self.people = [[SensorsAnalyticsPeople alloc] initWithSDK:self];
        
        self.serverURL = serverURL;
        self.configureURL = configureURL;
        self.vtrackServerURL = vtrackServerURL;
        _debugMode = debugMode;
        
        _flushInterval = 15 * 1000;
        _flushBulkSize = 100;
        _vtrackWindow = nil;
        _autoTrack = NO;
        _appRelaunched = NO;
        _referrerScreenUrl = nil;
        _lastScreenTrackProperties = nil;
        
        _filterControllers = [[NSMutableArray alloc] init];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        
        self.checkForEventBindingsOnActive = YES;
        self.flushBeforeEnterBackground = YES;
        
        self.safariRequestInProgress = NO;

        self.messageQueue = [[MessageQueueBySqlite alloc] initWithFilePath:[self filePathForData:@"message-v2"]];
        if (self.messageQueue == nil) {
            SADebug(@"SqliteException: init Message Queue in Sqlite fail");
        }
        
        //打开debug模式，弹出提示
        if (_debugMode != SensorsAnalyticsDebugOff) {
            [self showDebugModeWarning];
        }

        // 取上一次进程退出时保存的distinctId、loginId、superProperties和eventBindings
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
        
        NSString *label = [NSString stringWithFormat:@"com.sensorsdata.%@.%p", @"test", self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        [self setUpListeners];
        
#ifndef SENSORS_ANALYTICS_DISABLE_VTRACK
        [self executeEventBindings:self.eventBindings];
#endif
        // XXX: App Active 的时候会获取配置，此处不需要获取
//        [self checkForConfigure];
        // XXX: App Active 的时候会启动计时器，此处不需要启动
//        [self startFlushTimer];
    }
    
    SAError(@"%@ initialized the instance of Sensors Analytics SDK with server url '%@', configure url '%@'",
            self, serverURL, configureURL);
    
    return self;
}

- (void)showDebugModeWarning {
    @try {
        NSString *alertTitle = @"神策重要提示";
        NSString *alertMessage = nil;
        if (_debugMode == SensorsAnalyticsDebugOnly) {
            alertMessage = @"现在您打开了'DEBUG_ONLY'模式，此模式下只校验数据但不导入数据，数据出错时会以 App Crash 的方式提示开发者，请上线前一定关闭。";
        } else if (_debugMode == SensorsAnalyticsDebugAndTrack) {
            alertMessage = @"现在您打开了'DEBUG_AND_TRACK'模式，此模式下会校验数据并且导入数据，数据出错时会以 App Crash 的方式提示开发者，请上线前一定关闭。";
        } else {
            return;
        }

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            UIAlertController *connectAlert = [UIAlertController
                                               alertControllerWithTitle:alertTitle
                                               message:alertMessage
                                               preferredStyle:UIAlertControllerStyleAlert];

            [connectAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }]];

            UIWindow   *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            alertWindow.rootViewController = [[UIViewController alloc] init];
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            [alertWindow makeKeyAndVisible];
            [alertWindow.rootViewController presentViewController:connectAlert animated:YES completion:nil];
        } else {
            UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [connectAlert show];
        }
    } @catch (NSException *exception) {
    } @finally {
    }
}

- (void)enableEditingVTrack {
#ifndef SENSORS_ANALYTICS_DISABLE_VTRACK
    dispatch_async(dispatch_get_main_queue(), ^{
        // 5 秒
        self.vtrackConnectorTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                                     target:self
                                                                   selector:@selector(connectToVTrackDesigner)
                                                                   userInfo:nil
                                                                    repeats:YES];
    });
#endif
}

- (BOOL)isFirstDay {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *current = [dateFormatter stringFromDate:[NSDate date]];

    return [[self firstDay] isEqualToString:current];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request {
    return [self showUpWebView:webView WithRequest:request andProperties:nil];
}

- (BOOL)showUpWebView:(id)webView WithRequest:(NSURLRequest *)request andProperties:(NSDictionary *)propertyDict {
    SADebug(@"showUpWebView");
    if (webView == nil) {
        SADebug(@"showUpWebView == nil");
        return NO;
    }

    if (request == nil) {
        SADebug(@"request == nil");
        return NO;
    }

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

    NSString *scheme = @"sensorsanalytics://getAppInfo";
    NSString *js = [NSString stringWithFormat:@"sensorsdata_app_js_bridge_call_js('%@')", jsonString];
    if ([webView isKindOfClass:[UIWebView class]] == YES) {//UIWebView
        SADebug(@"showUpWebView: UIWebView");
        if ([request.URL.absoluteString rangeOfString:scheme].location != NSNotFound) {
            [webView stringByEvaluatingJavaScriptFromString:js];
            return YES;
        }
        return NO;
    }
#if defined(supportsWKWebKit )
    else if([webView isKindOfClass:[WKWebView class]] == YES) {//WKWebView
        SADebug(@"showUpWebView: WKWebView");
        if ([request.URL.absoluteString rangeOfString:scheme].location != NSNotFound) {
            [webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                NSLog(@"response: %@ error: %@", response, error);
            }];
            return YES;
        }
        return NO;
    }
#endif
    else{
        SADebug(@"showUpWebView: not UIWebView or WKWebView");
        return NO;
    }
}

- (NSMutableDictionary *)webViewJavascriptBridgeCallbackInfo {
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    [libProperties setValue:@"iOS" forKey:@"type"];
    if ([self loginId] != nil) {
        [libProperties setValue:[self loginId] forKey:@"distinct_id"];
        [libProperties setValue:[NSNumber numberWithBool:YES] forKey:@"is_login"];
    } else{
        [libProperties setValue:[self distinctId] forKey:@"distinct_id"];
        [libProperties setValue:[NSNumber numberWithBool:NO] forKey:@"is_login"];
    }
    return [libProperties copy];
}

- (void)login:(NSString *)loginId {
    if (loginId == nil || loginId.length == 0) {
        SAError(@"%@ cannot login blank login_id: %@", self, loginId);
        return;
    }
    if (loginId.length > 255) {
        SAError(@"%@ max length of login_id is 255, login_id: %@", self, loginId);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        if (![loginId isEqualToString:[self loginId]]) {
            self.loginId = loginId;
            [self archiveLoginId];
            if (![loginId isEqualToString:[self distinctId]]) {
                self.originalId = [self distinctId];
                [self track:@"$SignUp" withProperties:nil withType:@"track_signup"];
            }
        }
    });
}

- (void)logout {
    self.loginId = NULL;
    [self archiveLoginId];
}

- (NSString *)anonymousId {
    return _distinctId;
}

- (void)resetAnonymousId {
    BOOL isReal;
    self.distinctId = [[self class] getUniqueHardwareId:&isReal];
    [self archiveDistinctId];
}

- (void)enableAutoTrack {
    _autoTrack = YES;
    [self _enableAutoTrack];
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
        
        if (![self.messageQueue removeFirstRecords:flushSize withType:type]) {
            SAError(@"Failed to remove records from SQLite.");
            break;
        }
    }
}

- (void)_flush:(BOOL) vacuumAfterFlushing {
    // 使用 Post 发送数据
    BOOL (^flushByPost)(NSArray *, NSString *) = ^(NSArray *recordArray, NSString *type) {
        NSString *jsonString;
        NSData *zippedData;
        NSString *b64String;
        NSString *postBody;
        @try {
            // 1. 先完成这一系列Json字符串的拼接
            jsonString = [NSString stringWithFormat:@"[%@]",[recordArray componentsJoinedByString:@","]];
            // 2. 使用gzip进行压缩
            zippedData = [LFCGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
            // 3. base64
            b64String = [zippedData sa_base64EncodedString];
            b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                  (CFStringRef)b64String,
                                                                                  NULL,
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                  kCFStringEncodingUTF8));
        
            postBody = [NSString stringWithFormat:@"gzip=1&data_list=%@", b64String];
        } @catch (NSException *exception) {
            SAError(@"%@ flushByPost format data error: %@", self, exception);
            return YES;
        }
        
        NSURL *URL = [NSURL URLWithString:self.serverURL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        if ([type isEqualToString:@"SFSafariViewController"]) {
            // 渠道追踪请求，需要从 UserAgent 中解析 OS 信息用于模糊匹配
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                NSString* userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
            });
        } else {
            // 普通事件请求，使用标准 UserAgent
            [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
        }
        if (_debugMode == SensorsAnalyticsDebugOnly) {
            [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
        }
        
        dispatch_semaphore_t flushSem = dispatch_semaphore_create(0);
        __block BOOL flushSucc = YES;
        
        void (^block)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
                SAError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
                flushSucc = NO;
                dispatch_semaphore_signal(flushSem);
                return;
            }
            
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
            if([urlResponse statusCode] != 200) {
                NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    SAError(@"==========================================================================");
                    SAError(@"%@ invalid message: %@", self, jsonString);
                    SAError(@"%@ ret_code: %ld", self, [urlResponse statusCode]);
                    SAError(@"%@ ret_content: %@", self, urlResponseContent);
                    
                    if ([urlResponse statusCode] >= 300) {
                        @throw [SensorsAnalyticsDebugException exceptionWithName:@"IllegalDataException"
                                                                          reason:errMsg
                                                                        userInfo:nil];
                    }
                } else {
                    SAError(@"%@", errMsg);
                    if ([urlResponse statusCode] >= 300) {
                        flushSucc = NO;
                    }
                }
            } else {
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    SAError(@"==========================================================================");
                    SAError(@"%@ valid message: %@", self, jsonString);
                }
            }
            
            dispatch_semaphore_signal(flushSem);
        };
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:block];
        
        [task resume];
#else
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
         ^(NSURLResponse *response, NSData* data, NSError *error) {
             return block(data, response, error);
        }];
#endif
        
        dispatch_semaphore_wait(flushSem, DISPATCH_TIME_FOREVER);
        
        return flushSucc;
    };
    
    [self flushByType:@"Post" withSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1) andFlushMethod:flushByPost];
#ifdef SENSORS_ANALYTICS_IOS_MATCHING_WITH_COOKIE
    // 使用 SFSafariViewController 发送数据 (>= iOS 9.0)
    BOOL (^flushBySafariVC)(NSArray *, NSString *) = ^(NSArray *recordArray, NSString *type) {
        if (self.safariRequestInProgress) {
            return NO;
        }
        
        self.safariRequestInProgress = YES;
        
        Class SFSafariViewControllerClass = NSClassFromString(@"SFSafariViewController");
        if (!SFSafariViewControllerClass) {
            SAError(@"Cannot use cookie-based installation tracking. Please import the SafariService.framework.");
            self.safariRequestInProgress = NO;
            return YES;
        }
        
        // 1. 先完成这一系列Json字符串的拼接
        NSString *jsonString = [NSString stringWithFormat:@"[%@]",[recordArray componentsJoinedByString:@","]];
        // 2. 使用gzip进行压缩
        NSData *zippedData = [LFCGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        // 3. base64
        NSString *b64String = [zippedData sa_base64EncodedString];
        b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                  (CFStringRef)b64String,
                                                                                  NULL,
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                  kCFStringEncodingUTF8));
        
        NSURL *url = [NSURL URLWithString:self.serverURL];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        if (components.query.length > 0) {
            NSString *urlQuery = [[NSString alloc] initWithFormat:@"%@&gzip=1&data_list=%@", components.percentEncodedQuery, b64String];
            components.percentEncodedQuery = urlQuery;
        } else {
            NSString *urlQuery = [[NSString alloc] initWithFormat:@"gzip=1&data_list=%@", b64String];
            components.percentEncodedQuery = urlQuery;
        }
        
        NSURL *postUrl = [components URL];
        
        // Must be on next run loop to avoid a warning
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIViewController *safController = [[SFSafariViewControllerClass alloc] initWithURL:postUrl];
            
            UIViewController *windowRootController = [[UIViewController alloc] init];
            
            if (self.vtrackWindow == nil) {
                self.secondWindow = [[UIWindow alloc] initWithFrame:[[[[UIApplication sharedApplication] delegate] window] bounds]];
            } else {
                self.secondWindow = [[UIWindow alloc] initWithFrame:[self.vtrackWindow bounds]];
            }
            self.secondWindow.rootViewController = windowRootController;
            self.secondWindow.windowLevel = UIWindowLevelNormal - 1;
            [self.secondWindow setHidden:NO];
            [self.secondWindow setAlpha:0];
            
            // Add the safari view controller using view controller containment
            [windowRootController addChildViewController:safController];
            [windowRootController.view addSubview:safController.view];
            [safController didMoveToParentViewController:windowRootController];
            
            // Give a little bit of time for safari to load the request.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Remove the safari view controller from view controller containment
                [safController willMoveToParentViewController:nil];
                [safController.view removeFromSuperview];
                [safController removeFromParentViewController];
                
                // Remove the window and release it's strong reference. This is important to ensure that
                // applications using view controller based status bar appearance are restored.
                [self.secondWindow removeFromSuperview];
                self.secondWindow = nil;
                
                self.safariRequestInProgress = NO;
                
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    SAError(@"%@ The validation in DEBUG mode is unavailable while using track_installtion. Please check the result with 'debug_data_viewer'.", self);
                    SAError(@"%@ 使用 track_installation 时无法直接获得 Debug 模式数据校验结果，请登录 Sensors Analytics 并进入 '数据接入辅助工具' 查看校验结果。", self);
                }
            });
        });
        return YES;
    };
    [self flushByType:@"SFSafariViewController" withSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1) andFlushMethod:flushBySafariVC];
#else
    [self flushByType:@"SFSafariViewController" withSize:(_debugMode == SensorsAnalyticsDebugOff ? 50 : 1) andFlushMethod:flushByPost];
#endif
    
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

- (BOOL) isValidName : (NSString *) name {
    return [self.regexTestName evaluateWithObject:name];
}

- (NSString *)filePathForData:(NSString *)data {
    NSString *filename = [NSString stringWithFormat:@"sensorsanalytics-%@.plist", data];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    SADebug(@"filepath for %@ is %@", data, filepath);
    return filepath;
}

- (void)enqueueWithType:(NSString *)type andEvent:(NSDictionary *)e {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:e];
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:[event objectForKey:@"properties"]];
    
    NSString *from_vtrack = [properties objectForKey:@"$from_vtrack"];
    if (from_vtrack != nil && [from_vtrack length] > 0) {
        // 来自可视化埋点的事件
        BOOL binding_depolyed = [[properties objectForKey:@"$binding_depolyed"] boolValue];
        if (!binding_depolyed) {
            // 未部署的事件，不发送正式的track
            return;
        }
        
        NSString *binding_trigger_id = [[properties objectForKey:@"$binding_trigger_id"] stringValue];
        
        NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] initWithDictionary:[event objectForKey:@"lib"]];
        
        [libProperties setValue:@"vtrack" forKey:@"$lib_method"];
        [libProperties setValue:binding_trigger_id forKey:@"$lib_detail"];
        
        [properties removeObjectsForKeys:@[@"$binding_depolyed", @"$binding_path", @"$binding_trigger_id"]];
        
        [event setObject:properties forKey:@"properties"];
        [event setObject:libProperties forKey:@"lib"];
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if ([properties objectForKey:@"$ios_install_source"]) {
        [self.messageQueue addObejct:event withType:@"SFSafariViewController"];
    } else {
#endif
        [self.messageQueue addObejct:event withType:@"Post"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    }
#endif
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withType:(NSString *)type {
    // 对于type是track数据，它们的event名称是有意义的
    if ([type isEqualToString:@"track"]) {
        if (event == nil || [event length] == 0) {
            NSString *errMsg = @"SensorsAnalytics track called with empty event parameter";
            if (_debugMode != SensorsAnalyticsDebugOff) {
                @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                  reason:errMsg
                                                                userInfo:nil];
            } else {
                SAError(@"%@", errMsg);
                return;
            }
        }
        if (![self isValidName:event]) {
            NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
            if (_debugMode != SensorsAnalyticsDebugOff) {
                @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                  reason:errMsg
                                                                userInfo:nil];
            } else {
                SAError(@"%@", errMsg);
                return;
            }
        }
    }
    
    if (propertieDict) {
        if (![self assertPropertyTypes:[propertieDict copy] withEventType:type]) {
            SAError(@"%@ failed to track event.", self);
            return;
        }
    }
    
    NSNumber *timeStamp = @([[self class] getCurrentTime]);
    
    NSMutableDictionary *libProperties = [[NSMutableDictionary alloc] init];
    
    [libProperties setValue:[_automaticProperties objectForKey:@"$lib"] forKey:@"$lib"];
    [libProperties setValue:[_automaticProperties objectForKey:@"$lib_version"] forKey:@"$lib_version"];
    
    id app_version = [_automaticProperties objectForKey:@"$app_version"];
    if (app_version) {
        [libProperties setValue:app_version forKey:@"$app_version"];
    }
    
    [libProperties setValue:@"code" forKey:@"$lib_method"];
    
#ifndef SENSORS_ANALYTICS_DISABLE_CALL_STACK
    NSArray *syms = [NSThread callStackSymbols];
    
    if ([syms count] > 2) {
        NSString *trace = [syms objectAtIndex:2];
        
        NSRange start = [trace rangeOfString:@"["];
        NSRange end = [trace rangeOfString:@"]"];
        if (start.location != NSNotFound && end.location != NSNotFound && end.location > start.location) {
            NSString *trace_info = [trace substringWithRange:NSMakeRange(start.location+1, end.location-(start.location+1))];
            NSRange split = [trace_info rangeOfString:@" "];
            NSString *class = [trace_info substringWithRange:NSMakeRange(0, split.location)];
            NSString *function = [trace_info substringWithRange:NSMakeRange(split.location + 1, trace_info.length-(split.location + 1))];
            
            NSString *detail = [NSString stringWithFormat:@"%@##%@####", class, function];
            [libProperties setValue:detail forKey:@"$lib_detail"];
        }
    }
#endif

    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        if ([type isEqualToString:@"track"] || [type isEqualToString:@"track_signup"]) {
            // track / track_signup 类型的请求，还是要加上各种公共property
            // 这里注意下顺序，按照优先级从低到高，依次是automaticProperties, superProperties和propertieDict
            [p addEntriesFromDictionary:_automaticProperties];
            [p addEntriesFromDictionary:_superProperties];

            // 每次 track 时手机网络状态
            NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
            [p setObject:networkType forKey:@"$network_type"];
            if ([networkType isEqualToString:@"WIFI"]) {
                [p setObject:@YES forKey:@"$wifi"];
            } else {
                [p setObject:@NO forKey:@"$wifi"];
            }

            NSDictionary *eventTimer = self.trackTimer[event];
            if (eventTimer) {
                [self.trackTimer removeObjectForKey:event];
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                SensorsAnalyticsTimeUnit timeUnit = [[eventTimer valueForKey:@"timeUnit"] intValue];
                
                long eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [timeStamp longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [timeStamp longValue] - [eventBegin longValue];
                }

                if (eventDuration < 0) {
                    eventDuration = 0;
                }

                switch (timeUnit) {
                    case SensorsAnalyticsTimeUnitHours:
                        eventDuration = eventDuration / 60;
                    case SensorsAnalyticsTimeUnitMinutes:
                        eventDuration = eventDuration / 60;
                    case SensorsAnalyticsTimeUnitSeconds:
                        eventDuration = eventDuration / 1000;
                    case SensorsAnalyticsTimeUnitMilliseconds:
                        break;
                }
                
                [p setObject:@(eventDuration) forKey:@"event_duration"];
            }
        }
        
        if (propertieDict) {
            for (id key in propertieDict) {
                NSObject *obj = propertieDict[key];
                if ([obj isKindOfClass:[NSDate class]]) {
                    // 序列化所有 NSDate 类型
                    NSString *dateStr = [_dateFormatter stringFromDate:(NSDate *)obj];
                    [p setObject:dateStr forKey:key];
                } else {
                    [p setObject:obj forKey:key];
                }
            }
        }
        
        NSDictionary *e;
        NSString *bestId;
        if ([self loginId] != nil) {
            bestId = [self loginId];
        } else{
            bestId = [self distinctId];
        }

        if ([type isEqualToString:@"track_signup"]) {
            e = @{
                  @"event": event,
                  @"properties": [NSDictionary dictionaryWithDictionary:p],
                  @"distinct_id": bestId,
                  @"original_id": self.originalId,
                  @"time": timeStamp,
                  @"type": type,
                  @"lib": libProperties,
                  };
        } else if([type isEqualToString:@"track"]){
            //  是否首日访问
            if ([self isFirstDay]) {
                [p setObject:@YES forKey:@"$is_first_day"];
            } else {
                [p setObject:@NO forKey:@"$is_first_day"];
            }
            e = @{
                  @"event": event,
                  @"properties": [NSDictionary dictionaryWithDictionary:p],
                  @"distinct_id": bestId,
                  @"time": timeStamp,
                  @"type": type,
                  @"lib": libProperties,
                  };
        } else {
            // 此时应该都是对Profile的操作
            e = @{
                  @"properties": [NSDictionary dictionaryWithDictionary:p],
                  @"distinct_id": bestId,
                  @"time": timeStamp,
                  @"type": type,
                  @"lib": libProperties,
                  };
        }
        
        [self enqueueWithType:type andEvent:[e copy]];
        
        if (_debugMode != SensorsAnalyticsDebugOff) {
            // 在DEBUG模式下，直接发送事件
            [self _flush:NO];
        } else {
            // 否则，在满足发送条件时，发送事件
            if ([type isEqualToString:@"track_signup"] || [[self messageQueue] count] >= self.flushBulkSize) {
                // 2. 判断当前网络类型是否是3G/4G/WIFI
                NSString *networkType = [SensorsAnalyticsSDK getNetWorkStates];
                if (![networkType isEqualToString:@"NULL"] && ![networkType isEqualToString:@"2G"]) {
                    [self _flush:NO];
                }
            }
        }
    });
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    [self track:event withProperties:propertieDict withType:@"track"];
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil withType:@"track"];
}

- (void)trackTimer:(NSString *)event {
    [self trackTimer:event withTimeUnit:SensorsAnalyticsTimeUnitMilliseconds];
}

- (void)trackTimer:(NSString *)event withTimeUnit:(SensorsAnalyticsTimeUnit)timeUnit {
    if (![self isValidName:event]) {
        NSString *errMsg = [NSString stringWithFormat:@"Event name[%@] not valid", event];
        if (_debugMode != SensorsAnalyticsDebugOff) {
            @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                              reason:errMsg
                                                            userInfo:nil];
        } else {
            SAError(@"%@", errMsg);
            return;
        }
    }
    
    NSNumber *eventBegin = @([[self class] getCurrentTime]);
    
    dispatch_async(self.serialQueue, ^{
        self.trackTimer[event] = @{@"eventBegin" : eventBegin, @"eventAccumulatedDuration" : [NSNumber numberWithLong:0], @"timeUnit" : [NSNumber numberWithInt:timeUnit]};
    });
}

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        self.trackTimer = [NSMutableDictionary dictionary];
    });
}

- (void)trackSignUp:(NSString *)newDistinctId withProperties:(NSDictionary *)propertieDict {
    [self identify:newDistinctId];
    [self track:@"$SignUp" withProperties:propertieDict withType:@"track_signup"];
}

- (void)trackSignUp:(NSString *)newDistinctId {
    [self identify:newDistinctId];
    [self track:@"$SignUp" withProperties:nil withType:@"track_signup"];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    BOOL isFirstTrackInstallation = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasTrackInstallation"]) {
        isFirstTrackInstallation = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTrackInstallation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (isFirstTrackInstallation) {
        // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once

        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        NSString *idfa = [self getIDFA];
        if (idfa != nil) {
            [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:@"$ios_install_source"];
        } else {
            [properties setValue:@"" forKey:@"$ios_install_source"];
        }

        if (propertyDict != nil) {
            [properties addEntriesFromDictionary:propertyDict];
        }

        // 先发送 track
        [self track:event withProperties:properties withType:@"track"];
    
        // 再发送 profile_set_once
        [self track:nil withProperties:properties withType:@"profile_set_once"];
    }
}

- (void)trackInstallation:(NSString *)event {
    BOOL isFirstTrackInstallation = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasTrackInstallation"]) {
        isFirstTrackInstallation = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasTrackInstallation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    if (isFirstTrackInstallation) {
        // 追踪渠道是特殊功能，需要同时发送 track 和 profile_set_once
    
        // 通过 '$ios_install_source' 属性标记渠道追踪请求
        NSString *idfa = [self getIDFA];
        NSDictionary *properties = nil;
        if (idfa != nil) {
            properties = @{@"$ios_install_source" : [NSString stringWithFormat:@"idfa=%@", idfa]};
        } else {
            properties = @{@"$ios_install_source" : @""};
        }
        // 先发送 track
        [self track:event withProperties:properties withType:@"track"];
    
        // 再发送 profile_set_once
        [self track:nil withProperties:properties withType:@"profile_set_once"];
    }
}

- (NSString  *)getIDFA {
    NSString *idfa = nil;
    @try {
#if defined(SENSORS_ANALYTICS_IDFA)
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            NSString *temp = [uuid UUIDString];
            // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
            // 00000000-0000-0000-0000-000000000000
            if (temp && ![temp hasPrefix:@"00000000"]) {
                idfa = temp;
            }
        }
        #endif
        return idfa;
    } @catch (NSException *exception) {
        return idfa;
    }
}

- (void)filterAutoTrackControllers:(NSArray *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [_filterControllers addObjectsFromArray:controllers];

    //去重
    NSSet *set = [NSSet setWithArray:_filterControllers];
    if (set != nil) {
        _filterControllers = [NSMutableArray arrayWithArray:[set allObjects]];
    } else{
        _filterControllers = [[NSMutableArray alloc] init];
    }
}

- (void)identify:(NSString *)distinctId {
    if (distinctId == nil || distinctId.length == 0) {
        SAError(@"%@ cannot identify blank distinct id: %@", self, distinctId);
//        @throw [NSException exceptionWithName:@"InvalidDataException" reason:@"SensorsAnalytics distinct_id should not be nil or empty" userInfo:nil];
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

- (BOOL)assertPropertyTypes:(NSDictionary *)properties withEventType:(NSString *)eventType {
    for (id __unused k in properties) {
        // key 必须是NSString
        if (![k isKindOfClass: [NSString class]]) {
            NSString *errMsg = @"Property Key should by NSString";
            if (_debugMode != SensorsAnalyticsDebugOff) {
                @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                  reason:errMsg
                                                                userInfo:nil];
            } else {
                SAError(@"%@", errMsg);
                return NO;
            }
        }
        
        // key的名称必须符合要求
        if (![self isValidName: k]) {
            NSString *errMsg = [NSString stringWithFormat:@"property name[%@] is not valid", k];
            if (_debugMode != SensorsAnalyticsDebugOff) {
                @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                  reason:errMsg
                                                                userInfo:nil];
            } else {
                SAError(@"%@", errMsg);
                return NO;
            }
        }
        
        // value的类型检查
        if( ![properties[k] isKindOfClass:[NSString class]] &&
           ![properties[k] isKindOfClass:[NSNumber class]] &&
           ![properties[k] isKindOfClass:[NSNull class]] &&
           ![properties[k] isKindOfClass:[NSSet class]] &&
           ![properties[k] isKindOfClass:[NSDate class]]) {
            NSString * errMsg = [NSString stringWithFormat:@"%@ property values must be NSString, NSNumber, NSSet or NSDate. got: %@ %@", self, [properties[k] class], properties[k]];
            if (_debugMode != SensorsAnalyticsDebugOff) {
                @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                  reason:errMsg
                                                                userInfo:nil];
            } else {
                SAError(@"%@", errMsg);
                return NO;
            }
        }
        
        // NSSet 类型的属性中，每个元素必须是 NSString 类型
        if ([properties[k] isKindOfClass:[NSSet class]]) {
            NSEnumerator *enumerator = [((NSSet *)properties[k]) objectEnumerator];
            id object;
            while (object = [enumerator nextObject]) {
                if (![object isKindOfClass:[NSString class]]) {
                    NSString * errMsg = [NSString stringWithFormat:@"%@ value of NSSet must be NSString. got: %@ %@", self, [object class], object];
                    if (_debugMode != SensorsAnalyticsDebugOff) {
                        @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                          reason:errMsg
                                                                        userInfo:nil];
                    } else {
                        SAError(@"%@", errMsg);
                        return NO;
                    }
                }
                NSUInteger objLength = [((NSString *)object) lengthOfBytesUsingEncoding:NSUnicodeStringEncoding];
                if (objLength > PROPERTY_LENGTH_LIMITATION) {
                    NSString * errMsg = [NSString stringWithFormat:@"%@ The value in NSString is too long: %@", self, (NSString *)object];
                    if (_debugMode != SensorsAnalyticsDebugOff) {
                        @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                          reason:errMsg
                                                                        userInfo:nil];
                    } else {
                        SAError(@"%@", errMsg);
                        return NO;
                    }
                }
            }
        }
        
        // NSString 检查长度，但忽略部分属性
        if ([properties[k] isKindOfClass:[NSString class]] && ![k isEqualToString:@"$binding_path"]) {
            NSUInteger objLength = [((NSString *)properties[k]) lengthOfBytesUsingEncoding:NSUnicodeStringEncoding];
            if (objLength > PROPERTY_LENGTH_LIMITATION) {
                NSString * errMsg = [NSString stringWithFormat:@"%@ The value in NSString is too long: %@", self, (NSString *)properties[k]];
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                      reason:errMsg
                                                                    userInfo:nil];
                } else {
                    SAError(@"%@", errMsg);
                    return NO;
                }
            }
        }
        
        // profileIncrement的属性必须是NSNumber
        if ([eventType isEqualToString:@"profile_increment"]) {
            if (![properties[k] isKindOfClass:[NSNumber class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_increment value must be NSNumber. got: %@ %@", self, [properties[k] class], properties[k]];
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                      reason:errMsg
                                                                    userInfo:nil];
                } else {
                    SAError(@"%@", errMsg);
                    return NO;
                }
            }
        }
        
        // profileAppend的属性必须是个NSSet
        if ([eventType isEqualToString:@"profile_append"]) {
            if (![properties[k] isKindOfClass:[NSSet class]]) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ profile_append value must be NSSet. got %@ %@", self, [properties[k] class], properties[k]];
                if (_debugMode != SensorsAnalyticsDebugOff) {
                    @throw [SensorsAnalyticsDebugException exceptionWithName:@"InvalidDataException"
                                                                      reason:errMsg
                                                                    userInfo:nil];
                } else {
                    SAError(@"%@", errMsg);
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (NSDictionary *)collectAutomaticProperties {
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = [self deviceModel];
    struct CGSize size = [UIScreen mainScreen].bounds.size;
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_version"];
    [p setValue:carrier.carrierName forKey:@"$carrier"];
    [p addEntriesFromDictionary:@{
                                  @"$lib": @"iOS",
                                  @"$lib_version": [self libVersion],
                                  @"$manufacturer": @"Apple",
                                  @"$os": @"iOS",
                                  @"$os_version": [device systemVersion],
                                  @"$model": deviceModel,
                                  @"$screen_height": @((NSInteger)size.height),
                                  @"$screen_width": @((NSInteger)size.width),
                                      }];
    return [p copy];
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    propertyDict = [propertyDict copy];
    if (![self assertPropertyTypes:propertyDict withEventType:@"register_super_properties"]) {
        SAError(@"%@ failed to register super properties.", self);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        // 注意这里的顺序，发生冲突时是以propertyDict为准，所以它是后加入的
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        [tmp addEntriesFromDictionary:propertyDict];
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:_superProperties];
        if (tmp[property] != nil) {
            [tmp removeObjectForKey:property];
        }
        _superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveSuperProperties];
    });
    
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        _superProperties = @{};
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
    [self unarchiveEventBindings];
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
    NSString *archivedDistinctId = (NSString *)[self unarchiveFromFile:[self filePathForData:@"distinct_id"]];
    if (archivedDistinctId == nil) {
        BOOL isReal;
        self.distinctId = [[self class] getUniqueHardwareId:&isReal];
        [self archiveDistinctId];
    } else {
        self.distinctId = archivedDistinctId;
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

- (void)unarchiveEventBindings {
    NSSet *eventBindings = (NSSet *)[self unarchiveFromFile:[self filePathForData:@"event_bindings"]];
    SADebug(@"%@ unarchive event bindings %@", self, eventBindings);
    if (eventBindings == nil || ![eventBindings isKindOfClass:[NSSet class]]) {
        eventBindings = [NSSet set];
    }
    self.eventBindings = eventBindings;
}

- (void)archiveDistinctId {
    NSString *filePath = [self filePathForData:@"distinct_id"];
    if (![NSKeyedArchiver archiveRootObject:[[self distinctId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive distinctId", self);
    }
    SADebug(@"%@ archived distinctId", self);
}

- (void)archiveLoginId {
    NSString *filePath = [self filePathForData:@"login_id"];
    if (![NSKeyedArchiver archiveRootObject:[[self loginId] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive loginId", self);
    }
    SADebug(@"%@ archived loginId", self);
}

- (void)archiveFirstDay {
    NSString *filePath = [self filePathForData:@"first_day"];
    if (![NSKeyedArchiver archiveRootObject:[[self firstDay] copy] toFile:filePath]) {
        SAError(@"%@ unable to archive firstDay", self);
    }
    SADebug(@"%@ archived firstDay", self);
}

- (void)archiveSuperProperties {
    NSString *filePath = [self filePathForData:@"super_properties"];
    if (![NSKeyedArchiver archiveRootObject:[self.superProperties copy] toFile:filePath]) {
        SAError(@"%@ unable to archive super properties", self);
    }
    SADebug(@"%@ archive super properties data", self);
}

- (void)archiveEventBindings {
    NSString *filePath = [self filePathForData:@"event_bindings"];
    if (![NSKeyedArchiver archiveRootObject:[self.eventBindings copy] toFile:filePath]) {
        SAError(@"%@ unable to archive tracking events data", self);
    }
    SADebug(@"%@ archive tracking events data, %@", self, [self.eventBindings copy]);
}

#pragma mark - Network control

+ (NSString *)getNetWorkStates {
#ifdef SA_UT
    SADebug(@"In unit test, set NetWorkStates to wifi");
    return @"WIFI";
#endif
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    SAReachability *reachability = [SAReachability reachabilityForInternetConnection];
    SANetworkStatus status = [reachability currentReachabilityStatus];
    
    NSString* network = @"NULL";
    if (status == SAReachableViaWiFi) {
        network = @"WIFI";
    } else if (status == SAReachableViaWWAN) {
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
            network = @"2G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
            network = @"2G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
            network = @"3G";
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
            network = @"4G";
        }
    }
    
    return network;
#else
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"]valueForKeyPath:@"foregroundView"]subviews];
    //获取到网络返回码
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            //获取到状态栏
            int netType = [[child valueForKeyPath:@"dataNetworkType"]intValue];
            switch (netType) {
                case 0:
                    //无网模式
                    return @"NULL"
                case 1:
                    return @"2G";
                case 2:
                    return @"3G";
                case 3:
                    return @"4G";
                case 5:
                    return @"WIFI";
            }
        }
    }
    return @"NULL";
#endif
}

- (UInt64)flushInterval {
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(UInt64)interval {
    @synchronized(self) {
        _flushInterval = interval;
    }
    [self flush];
    [self startFlushTimer];
}

- (void)startFlushTimer {
    SADebug(@"starting flush timer.");
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_flushInterval > 0) {
            double interval = _flushInterval > 100 ? (double)_flushInterval / 1000.0 : 0.1f;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
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
        _flushBulkSize = bulkSize;
    }
}

- (UIWindow *)vtrackWindow {
    @synchronized(self) {
        return _vtrackWindow;
    }
}

- (void)setVtrackWindow:(UIWindow *)vtrackWindow {
    @synchronized(self) {
        _vtrackWindow = vtrackWindow;
    }
}

- (NSString *)getLastScreenUrl {
    return _referrerScreenUrl;
}

- (NSDictionary *)getLastScreenTrackProperties {
    return _lastScreenTrackProperties;
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
    
    [self _enableAutoTrack];
}

- (void)_enableAutoTrack {
    void (^block)(id, SEL, id) = ^(id obj, SEL sel, NSNumber* a) {
        if (_autoTrack) {
            UIViewController *controller = (UIViewController *)obj;
            if (!controller) {
                return;
            }
            
            Class klass = [controller class];
            if (!klass) {
                return;
            }

            NSString *screenName = NSStringFromClass(klass);
            if ([screenName isEqualToString:@"SFBrowserRemoteViewController"] ||
                [screenName isEqualToString:@"SFSafariViewController"] ||
                [screenName isEqualToString:@"UIInputWindowController"] ||
                [screenName isEqualToString:@"UINavigationController"] ||
                [screenName isEqualToString:@"UIApplicationRotationFollowingControllerNoTouches"]) {
                return;
            }
            
            //过滤用户设置的不被AutoTrack的Controllers
            if (_filterControllers != nil && _filterControllers.count > 0) {
                @try {
                    for (id controller in _filterControllers) {
                        if ([screenName isEqualToString:controller]) {
                            return;
                        }
                    }
                } @catch (NSException *exception) {
                    SAError(@" unable to parse filterController");
                }
            }

            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            [properties setValue:NSStringFromClass(klass) forKey:SCREEN_NAME_PROPERTY];

            @try {
                NSString *controllerTitle = controller.navigationItem.title;
                if (controllerTitle != nil) {
                    [properties setValue:controllerTitle forKey:@"$title"];
                }
            } @catch (NSException *exception) {

            }

            if ([controller conformsToProtocol:@protocol(SAAutoTracker)]) {
                UIViewController<SAAutoTracker> *autoTrackerController = (UIViewController<SAAutoTracker> *)controller;
                [properties addEntriesFromDictionary:[autoTrackerController getTrackProperties]];
                _lastScreenTrackProperties = [autoTrackerController getTrackProperties];
            }

            if ([controller conformsToProtocol:@protocol(SAScreenAutoTracker)]) {
                UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)controller;
                NSString *currentScreenUrl = [screenAutoTrackerController getScreenUrl];

                [properties setValue:currentScreenUrl forKey:SCREEN_URL_PROPERTY];
                @synchronized(_referrerScreenUrl) {
                    if (_referrerScreenUrl) {
                        [properties setValue:_referrerScreenUrl forKey:SCREEN_REFERRER_URL_PROPERTY];
                    }
                    _referrerScreenUrl = currentScreenUrl;
                }
            }
            
            [self track:APP_VIEW_SCREEN_EVENT withProperties:properties];
        }
    };

    // 监听所有 UIViewController 显示事件
    if (_autoTrack) {
        [SASwizzler swizzleBoolSelector:@selector(viewWillAppear:)
                            onClass:[UIViewController class]
                          withBlock:block
                              named:@"track_view_screen"];
    }
}

- (void)trackViewScreen:(NSString *)url withProperties:(NSDictionary *)properties {
    NSMutableDictionary *trackProperties = [[NSMutableDictionary alloc] init];
    if (properties) {
        [trackProperties addEntriesFromDictionary:properties];
    }
    @synchronized(_lastScreenTrackProperties) {
        _lastScreenTrackProperties = properties;
    }

    [trackProperties setValue:url forKey:SCREEN_URL_PROPERTY];
    @synchronized(_referrerScreenUrl) {
        if (_referrerScreenUrl) {
            [trackProperties setValue:_referrerScreenUrl forKey:SCREEN_REFERRER_URL_PROPERTY];
        }
        _referrerScreenUrl = url;
    }
    [self track:APP_VIEW_SCREEN_EVENT withProperties:trackProperties];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    SADebug(@"%@ application will enter foreground", self);
    
    _appRelaunched = YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SADebug(@"%@ application did become active", self);
    
    // 是否首次启动
    BOOL isFirstStart = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        isFirstStart = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    // 遍历trackTimer,修改eventBegin为当前timeStamp
    dispatch_async(self.serialQueue, ^{
        NSNumber *timeStamp = @([[self class] getCurrentTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                [eventTimer setValue:timeStamp forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }
    });

    if (_autoTrack) {
        // 追踪 AppStart 事件
        [self track:APP_START_EVENT withProperties:@{
                                                     RESUME_FROM_BACKGROUND_PROPERTY : @(_appRelaunched),
                                                     APP_FIRST_START_PROPERTY : @(isFirstStart),
                                                     }];
        // 启动 AppEnd 事件计时器
        [self trackTimer:APP_END_EVENT withTimeUnit:SensorsAnalyticsTimeUnitSeconds];
    }
    
#ifndef SENSORS_ANALYTICS_DISABLE_VTRACK
    if (self.checkForEventBindingsOnActive) {
        [self checkForConfigure];
    }
#endif
    
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    SADebug(@"%@ application will resign active", self);
    
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SADebug(@"%@ application did enter background", self);
    
    // 遍历trackTimer
    // eventAccumulatedDuration = eventAccumulatedDuration + timeStamp - eventBegin
    dispatch_async(self.serialQueue, ^{
        NSNumber *timeStamp = @([[self class] getCurrentTime]);
        NSArray *keys = [self.trackTimer allKeys];
        NSString *key = nil;
        NSMutableDictionary *eventTimer = nil;
        for (key in keys) {
            eventTimer = [[NSMutableDictionary alloc] initWithDictionary:self.trackTimer[key]];
            if (eventTimer) {
                NSNumber *eventBegin = [eventTimer valueForKey:@"eventBegin"];
                NSNumber *eventAccumulatedDuration = [eventTimer objectForKey:@"eventAccumulatedDuration"];
                long eventDuration;
                if (eventAccumulatedDuration) {
                    eventDuration = [timeStamp longValue] - [eventBegin longValue] + [eventAccumulatedDuration longValue];
                } else {
                    eventDuration = [timeStamp longValue] - [eventBegin longValue];
                }

                [eventTimer setObject:[NSNumber numberWithLong:eventDuration] forKey:@"eventAccumulatedDuration"];
                [eventTimer setObject:timeStamp forKey:@"eventBegin"];
                self.trackTimer[key] = eventTimer;
            }
        }

    });

    if (_autoTrack) {
        // 追踪 AppEnd 事件
        [self track:APP_END_EVENT];
    }
    
    if (self.flushBeforeEnterBackground) {
        dispatch_async(self.serialQueue, ^{
            [self _flush:YES];
        });
    }
    
    if ([self.abtestDesignerConnection isKindOfClass:[SADesignerConnection class]]
        && ((SADesignerConnection *)self.abtestDesignerConnection).connected) {
        ((SADesignerConnection *)self.abtestDesignerConnection).sessionEnded = YES;
        [((SADesignerConnection *)self.abtestDesignerConnection) close];
    }
}

#pragma mark - SensorsData VTrack Analytics

- (void)checkForConfigure {
    SADebug(@"%@ starting configure check", self);
    
    if (self.configureURL == nil || self.configureURL.length < 1) {
        return;
    }
    
    void (^block)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            SAError(@"%@ configure check http error: %@", self, error);
            return;
        }
        
        NSError *parseError;
        NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError) {
            SAError(@"%@ configure check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            return;
        }
        
        // 可视化埋点配置
        NSDictionary *rawEventBindings = object[@"event_bindings"];
        if (rawEventBindings && [rawEventBindings isKindOfClass:[NSDictionary class]]) {
            NSArray *eventBindings = rawEventBindings[@"events"];
            if (eventBindings && [eventBindings isKindOfClass:[NSArray class]]) {
                // Finished bindings are those which should no longer be run.
                [self.eventBindings makeObjectsPerformSelector:NSSelectorFromString(@"stop")];
                
                NSMutableSet *parsedEventBindings = [NSMutableSet set];
                for (id obj in eventBindings) {
                    SAEventBinding *binding = [SAEventBinding bindingWithJSONObject:obj];
                    if (binding) {
                        [binding execute];
                        [parsedEventBindings addObject:binding];
                    }
                }
                
                SADebug(@"%@ found %lu tracking events: %@", self, (unsigned long)[parsedEventBindings count], parsedEventBindings);
                
                self.eventBindings = parsedEventBindings;
                [self archiveEventBindings];
            }
        }
        
        // 可视化埋点服务地址
        if (_vtrackServerURL == nil) {
            NSString *vtrackServerUrl = object[@"vtrack_server_url"];
            
            // XXX: 为了兼容历史版本，有三种方式设置可视化埋点管理界面服务地址，优先级从高到低：
            //  1. 从 SDK 构造函数传入
            //  2. 从 SDK 配置分发的结果中获取（1.6+）
            //  3. 从 SDK 配置分发的 Url 中自动生成（兼容旧版本）
            
            if (vtrackServerUrl && [vtrackServerUrl length] > 0) {
                _vtrackServerURL = vtrackServerUrl;
            } else {
                // 根据参数 <code>configureURL</code> 自动生成 <code>vtrackServerURL</code>
                NSURL *url = [NSURL URLWithString:_configureURL];
                
                // 将 URI Path (/api/vtrack/config/iOS.conf) 替换成 VTrack WebSocket 的 '/api/ws'
                UInt64 pathComponentSize = [url pathComponents].count;
                for (UInt64 i = 2; i < pathComponentSize; ++i) {
                    url = [url URLByDeletingLastPathComponent];
                }
                url = [url URLByAppendingPathComponent:@"ws"];
                
                // 将 URL Scheme 替换成 'ws:'
                NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
                components.scheme = @"ws";
                
                _vtrackServerURL = [components.URL absoluteString];
            }
        }
        
        SADebug(@"%@ initialized the VTrack with server url: %@", self, _vtrackServerURL);
    };
    
    NSURL *URL = [NSURL URLWithString:self.configureURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"GET"];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:block];
    
    [task resume];
#else
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData* data, NSError *error) {
         return block(data, response, error);
     }];
#endif
}

- (void)connectToVTrackDesigner {
    if (self.vtrackServerURL == nil || self.vtrackServerURL.length < 1) {
        return;
    }
    
    if ([self.abtestDesignerConnection isKindOfClass:[SADesignerConnection class]]
            && ((SADesignerConnection *)self.abtestDesignerConnection).connected) {
        SADebug(@"VTrack connection already exists");
    } else {
        static UInt64 oldInterval;

        __weak SensorsAnalyticsSDK *weakSelf = self;
        
        void (^connectCallback)(void) = ^{
            __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
            oldInterval = strongSelf.flushInterval;
            strongSelf.flushInterval = 1000;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            if (strongSelf) {
                NSMutableSet *eventBindings = [strongSelf.eventBindings mutableCopy];
                
                SADesignerConnection *connection = strongSelf.abtestDesignerConnection;
                
                SAEventBindingCollection *bindingCollection = [[SAEventBindingCollection alloc] initWithEvents:eventBindings];
                [connection setSessionObject:bindingCollection forKey:@"event_bindings"];
                
                void (^block)(id, SEL, NSString*, id) = ^(id obj, SEL sel, NSString *type, NSDictionary *e) {
                    if (![type isEqualToString:@"track"]) {
                        return;
                    }
                    
                    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:e];
                    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:[event objectForKey:@"properties"]];
                    
                    NSString *from_vtrack = [properties objectForKey:@"$from_vtrack"];
                    if (from_vtrack == nil || [from_vtrack length] < 1) {
                        return;
                    }
                    
                    // 来自可视化埋点的事件
                    BOOL binding_depolyed = [[properties objectForKey:@"$binding_depolyed"] boolValue];
                    NSInteger binding_trigger_id = [[properties objectForKey:@"$binding_trigger_id"] integerValue];
                    NSString *binding_path = [properties objectForKey:@"$binding_path"];
                    
                    [properties removeObjectsForKeys:@[@"$binding_depolyed", @"$binding_trigger_id", @"$binding_path"]];
                    [event setObject:properties forKey:@"properties"];
                    
                    NSDictionary *payload = [[NSDictionary alloc] initWithObjectsAndKeys:
                                             binding_depolyed ? @YES : @NO, @"depolyed",
                                             @(binding_trigger_id), @"trigger_id",
                                             binding_path, @"path",
                                             event, @"event", nil];
                    
                    SADesignerTrackMessage *message = [SADesignerTrackMessage messageWithPayload:payload];
                    [connection sendMessage:message];
                };
                
                [SASwizzler swizzleSelector:@selector(enqueueWithType:andEvent:)
                                    onClass:[SensorsAnalyticsSDK class]
                                  withBlock:block
                                      named:@"track_properties"];
            }
        };
        
        void (^disconnectCallback)(void) = ^{
            __strong SensorsAnalyticsSDK *strongSelf = weakSelf;
            strongSelf.flushInterval = oldInterval;
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            if (strongSelf) {
                SADesignerConnection *connection = strongSelf.abtestDesignerConnection;
                id bindingCollection = [connection sessionObjectForKey:@"event_bindings"];
                if (bindingCollection && [bindingCollection conformsToProtocol:@protocol(SADesignerSessionCollection)]) {
                    [bindingCollection cleanup];
                }
                
                [strongSelf executeEventBindings:strongSelf.eventBindings];
                
                [SASwizzler unswizzleSelector:@selector(enqueueWithType:andEvent:)
                                      onClass:[SensorsAnalyticsSDK class]
                                        named:@"track_properties"];
            }
        };
        
        NSURL *designerURL = [NSURL URLWithString:self.vtrackServerURL];
        self.abtestDesignerConnection = [[SADesignerConnection alloc] initWithURL:designerURL
                                                                       keepTrying:YES
                                                                  connectCallback:connectCallback
                                                               disconnectCallback:disconnectCallback];
        
    }
    
    if (self.vtrackConnectorTimer) {
        [self.vtrackConnectorTimer invalidate];
    }
    self.vtrackConnectorTimer = nil;
}

- (void)executeEventBindings:(NSSet*) eventBindings {
    if (eventBindings) {
        for (id binding in eventBindings) {
            if ([binding isKindOfClass:[SAEventBinding class]]) {
                [binding execute];
            }
        }
        SADebug(@"%@ execute event bindings %@", self, eventBindings);
    }
}

@end

#pragma mark - People analytics

@implementation SensorsAnalyticsPeople {
    SensorsAnalyticsSDK *_sdk;
}

- (id)initWithSDK:(SensorsAnalyticsSDK *)sdk {
    self = [super init];
    if (self) {
        _sdk = sdk;
    }
    return self;
}

- (void)set:(NSDictionary *)profileDict {
    [_sdk track:nil withProperties:profileDict withType:@"profile_set"];
}

- (void)setOnce:(NSDictionary *)profileDict {
    [_sdk track:nil withProperties:profileDict withType:@"profile_set_once"];
}

- (void)set:(NSString *) profile to:(id)content {
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set"];
}

- (void)setOnce:(NSString *) profile to:(id)content {
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_set_once"];
}

- (void)unset:(NSString *) profile {
    [_sdk track:nil withProperties:@{profile: @""} withType:@"profile_unset"];
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    [_sdk track:nil withProperties:@{profile: amount} withType:@"profile_increment"];
}

- (void)increment:(NSDictionary *)profileDict {
    [_sdk track:nil withProperties:profileDict withType:@"profile_increment"];
}

- (void)append:(NSString *)profile by:(NSSet *)content {
    [_sdk track:nil withProperties:@{profile: content} withType:@"profile_append"];
}

- (void)deleteUser {
    [_sdk track:nil withProperties:@{} withType:@"profile_delete"];
}

@end
