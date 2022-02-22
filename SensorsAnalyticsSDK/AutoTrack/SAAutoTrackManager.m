//
// SAAutoTrackManager.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
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

#import "SAAutoTrackManager.h"
#import "SAConfigOptions.h"
#import "SARemoteConfigModel.h"
#import "SAModuleManager.h"
#import "SAAppLifecycle.h"
#import "SALog.h"
#import "UIApplication+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "SASwizzle.h"
#import "SAAppStartTracker.h"
#import "SAAppEndTracker.h"
#import "SAConstants+Private.h"
#import "UIGestureRecognizer+SAAutoTrack.h"
#import "SAGestureViewProcessorFactory.h"
#import "SACommonUtility.h"
#import "SAApplication.h"
#import "SensorsAnalyticsSDK+SAAutoTrack.h"
#import "UIViewController+SAPageLeave.h"

//event tracker plugins
#if __has_include("SACellClickHookDelegatePlugin.h")
#import "SACellClickHookDelegatePlugin.h"
#endif
#import "SACellClickDynamicSubclassPlugin.h"
#import "SAEventTrackerPluginManager.h"
#if __has_include("SAGesturePlugin.h")
#import "SAGesturePlugin.h"
#endif

@interface SAAutoTrackManager ()

@property (nonatomic, strong) SAAppStartTracker *appStartTracker;
@property (nonatomic, strong) SAAppEndTracker *appEndTracker;

@property (nonatomic, getter=isDisableSDK) BOOL disableSDK;
@property (nonatomic, assign) NSInteger autoTrackMode;

@end

@implementation SAAutoTrackManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAAutoTrackManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAAutoTrackManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _appStartTracker = [[SAAppStartTracker alloc] init];
        _appEndTracker = [[SAAppEndTracker alloc] init];
        _appViewScreenTracker = [[SAAppViewScreenTracker alloc] init];
        _appClickTracker = [[SAAppClickTracker alloc] init];
        _appPageLeaveTracker = [[SAAppPageLeaveTracker alloc] init];

        _disableSDK = NO;
        _autoTrackMode = kSAAutoTrackModeDefault;
        [self updateAutoTrackEventType];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteConfigModelChanged:) name:SA_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions {
    if ([SAApplication isAppExtension]) {
        configOptions.enableAutoTrack = NO;
    }
    _configOptions = configOptions;
    self.enable = configOptions.enableAutoTrack;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self enableAutoTrack];
        [self registerPlugins];
        return;
    }
    [self.appPageLeaveTracker.pageLeaveObjects removeAllObjects];
    [self unregisterPlugins];
}

#pragma mark - SAAutoTrackModuleProtocol

- (void)trackAppEndWhenCrashed {
    if (!self.enable) {
        return;
    }
    if (self.appEndTracker.isIgnored) {
        return;
    }
    [SACommonUtility performBlockOnMainThread:^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.appEndTracker autoTrackEvent];
        }
    }];
}

- (void)trackPageLeaveWhenCrashed {
    if (!self.enable) {
        return;
    }
    if (!self.configOptions.enableTrackPageLeave) {
        return;
    }
    [SACommonUtility performBlockOnMainThread:^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.appPageLeaveTracker trackEvents];
        }
    }];
}

#pragma mark - Notification

- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    if (!self.enable) {
        return;
    }
    NSDictionary *userInfo = sender.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    SAAppLifecycleState oldState = [userInfo[kSAAppLifecycleOldStateKey] integerValue];

    self.appStartTracker.passively = NO;
    self.appViewScreenTracker.passively = NO;

    // 被动启动
    if (oldState == SAAppLifecycleStateInit && newState == SAAppLifecycleStateStartPassively) {
        self.appStartTracker.passively = YES;
        self.appViewScreenTracker.passively = YES;
        
        [self.appStartTracker autoTrackEventWithProperties:SAModuleManager.sharedInstance.utmProperties];
        return;
    }

    // 冷（热）启动
    if (newState == SAAppLifecycleStateStart) {
        // 启动 AppEnd 事件计时器
        [self.appEndTracker trackTimerStartAppEnd];
        // 触发启动事件
        [self.appStartTracker autoTrackEventWithProperties:SAModuleManager.sharedInstance.utmProperties];
        // 热启动时触发被动启动的页面浏览事件
        if (oldState == SAAppLifecycleStateStartPassively) {
            [self.appViewScreenTracker trackEventOfLaunchedPassively];
        }
        return;
    }

    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        [self.appEndTracker autoTrackEvent];
    }
}

- (void)remoteConfigModelChanged:(NSNotification *)sender {
    @try {
        self.disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
        self.autoTrackMode = [[sender.object valueForKey:@"autoTrackMode"] integerValue];

        [self updateAutoTrackEventType];
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Public

- (BOOL)isAutoTrackEnabled {
    if (self.isDisableSDK) {
        SALogDebug(@"SDK is disabled");
        return NO;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return (self.configOptions.autoTrackEventType != SensorsAnalyticsEventTypeNone);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isEnabled = (autoTrackMode != kSAAutoTrackModeDisabledAll);
        if (!isEnabled) {
            SALogDebug(@"【remote config】AutoTrack Event is ignored by remote config");
        }
        return isEnabled;
    }
}

- (BOOL)isAutoTrackEventTypeIgnored:(SensorsAnalyticsAutoTrackEventType)eventType {
    if (self.isDisableSDK) {
        SALogDebug(@"SDK is disabled");
        return YES;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
    if (autoTrackMode == kSAAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return !(self.configOptions.autoTrackEventType & eventType);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isIgnored = (autoTrackMode == kSAAutoTrackModeDisabledAll) ? YES : !(autoTrackMode & eventType);
        if (isIgnored) {
            NSString *ignoredEvent = @"None";
            switch (eventType) {
                case SensorsAnalyticsEventTypeAppStart:
                    ignoredEvent = kSAEventNameAppStart;
                    break;

                case SensorsAnalyticsEventTypeAppEnd:
                    ignoredEvent = kSAEventNameAppEnd;
                    break;

                case SensorsAnalyticsEventTypeAppClick:
                    ignoredEvent = kSAEventNameAppClick;
                    break;

                case SensorsAnalyticsEventTypeAppViewScreen:
                    ignoredEvent = kSAEventNameAppViewScreen;
                    break;

                default:
                    break;
            }
            SALogDebug(@"【remote config】%@ is ignored by remote config", ignoredEvent);
        }
        return isIgnored;
    }
}

- (void)updateAutoTrackEventType {
    self.appStartTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppStart];
    self.appEndTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd];
    self.appViewScreenTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppViewScreen];
    self.appClickTracker.ignored = [self isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick];
}

- (BOOL)isGestureVisualView:(id)obj {
    if (!self.enable) {
        return NO;
    }
    if (![obj isKindOfClass:UIView.class]) {
        return NO;
    }
    UIView *view = (UIView *)obj;
    for (UIGestureRecognizer *gesture in view.gestureRecognizers) {
        if (gesture.sensorsdata_gestureTarget) {
            SAGeneralGestureViewProcessor *processor = [SAGestureViewProcessorFactory processorWithGesture:gesture];
            if (processor.isTrackable && processor.trackableView == gesture.view) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark – Private Methods

- (void)enableAutoTrack {
    // 监听所有 UIViewController 显示事件
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self enableAppViewScreenAutoTrack];
        [self enableAppClickAutoTrack];
        [self enableAppPageLeave];
    });
}

- (void)enableAppViewScreenAutoTrack {
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:)
                            withMethod:@selector(sa_autotrack_viewDidAppear:)
                                 error:NULL];
}

- (void)enableAppClickAutoTrack {
    // Actions & Events
    NSError *error = NULL;
    [UIApplication sa_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                         withMethod:@selector(sa_sendAction:to:from:forEvent:)
                              error:&error];
    if (error) {
        SALogError(@"Failed to swizzle sendAction:to:forEvent: on UIAppplication. Details: %@", error);
        error = NULL;
    }
}

- (void)enableAppPageLeave {
    if (!self.configOptions.enableTrackPageLeave) {
        return;
    }
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_pageLeave_viewDidAppear:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(sensorsdata_pageLeave_viewDidDisappear:) error:NULL];
}

- (void)registerPlugins {
    BOOL enableAppClick = self.configOptions.autoTrackEventType & SensorsAnalyticsEventTypeAppClick;
    if (!enableAppClick) {
        return;
    }
    //UITableView/UICollectionView Cell + AppClick plugin register
#if __has_include("SACellClickHookDelegatePlugin.h")
    [[SAEventTrackerPluginManager defaultManager] registerPlugin:[[SACellClickHookDelegatePlugin alloc] init]];
#else
    [[SAEventTrackerPluginManager defaultManager] registerPlugin:[[SACellClickDynamicSubclassPlugin alloc] init]];
#endif

    //UIGestureRecognizer + AppClick plugin register
#if __has_include("SAGesturePlugin.h")
    [[SAEventTrackerPluginManager defaultManager] registerPlugin:[[SAGesturePlugin alloc] init]];
#endif
}

- (void)unregisterPlugins {
    //unregister UITableView/UICollectionView cell click plugin
#if __has_include("SACellClickHookDelegatePlugin.h")
    [[SAEventTrackerPluginManager defaultManager] unregisterPlugin:[SACellClickHookDelegatePlugin class]];
#else
    [[SAEventTrackerPluginManager defaultManager] unregisterPlugin:[SACellClickDynamicSubclassPlugin class]];
#endif

    //unregister SAGesturePlugin
#if __has_include("SAGesturePlugin.h")
    [[SAEventTrackerPluginManager defaultManager] unregisterPlugin:[SAGesturePlugin class]];
#endif
}

@end

