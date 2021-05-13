//
// SAAppLifecycle.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/1.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAAppLifecycle.h"
#import "SALog.h"

NSNotificationName const kSAAppLifecycleStateWillChangeNotification = @"com.sensorsdata.SAAppLifecycleStateWillChange";
NSNotificationName const kSAAppLifecycleStateDidChangeNotification = @"com.sensorsdata.SAAppLifecycleStateDidChange";
NSString * const kSAAppLifecycleNewStateKey = @"new";
NSString * const kSAAppLifecycleOldStateKey = @"old";

@interface SAAppLifecycle ()

@property (nonatomic, assign) SAAppLifecycleState state;

@end

@implementation SAAppLifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = SAAppLifecycleStateInit;

        [self setupListeners];
        [self setupLaunchedState];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLaunchedState {
    dispatch_block_t mainThreadBlock = ^(){
#if TARGET_OS_IPHONE
        BOOL isAppStateBackground = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
#else
        BOOL isAppStateBackground = NO;
#endif
        self.state = isAppStateBackground ? SAAppLifecycleStateStartPassively : SAAppLifecycleStateStart;
    };

    if (@available(iOS 13.0, *)) {
        // iOS 13 及以上在异步主队列的 block 修改状态的原因:
        // 1. 保证在执行启动（被动启动）事件时（动态）公共属性设置完毕（通过监听 UIApplicationDidFinishLaunchingNotification 可以实现）
        // 2. 含有 SceneDelegate 的工程中延迟获取 applicationState 才是准确的（通过监听 UIApplicationDidFinishLaunchingNotification 获取不准确）
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    } else {
        // iOS 13 以下通过监听 UIApplicationDidFinishLaunchingNotification 的通知来处理被动启动和冷启动（非延迟初始化）的情况:
        // 1. iOS 13 以下被动启动时异步主队列的 block 不会执行
        // 2. iOS 13 以下不会含有 SceneDelegate
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
#endif
        // 处理 iOS 13 以下（冷启动）延迟初始化的情况
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    }
}

#pragma mark - Setter

- (void)setState:(SAAppLifecycleState)state {
    if (_state == state) {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[kSAAppLifecycleNewStateKey] = @(state);
    userInfo[kSAAppLifecycleOldStateKey] = @(_state);

    [[NSNotificationCenter defaultCenter] postNotificationName:kSAAppLifecycleStateWillChangeNotification object:self userInfo:userInfo];

    _state = state;

    [[NSNotificationCenter defaultCenter] postNotificationName:kSAAppLifecycleStateDidChangeNotification object:self userInfo:userInfo];
}

#pragma mark - Listener

- (void)setupListeners {
#if TARGET_OS_IPHONE
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
#endif
}

#if TARGET_OS_IPHONE
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    SALogDebug(@"%@ application did finish launching", self);
    
    BOOL isAppStateBackground = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
    self.state = isAppStateBackground ? SAAppLifecycleStateStartPassively : SAAppLifecycleStateStart;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SALogDebug(@"%@ application did become active", self);

    // 防止主动触发 UIApplicationDidBecomeActiveNotification
    if (![notification.object isKindOfClass:[UIApplication class]]) {
        return;
    }

    UIApplication *application = (UIApplication *)notification.object;
    if (application.applicationState != UIApplicationStateActive) {
        return;
    }

    self.state = SAAppLifecycleStateStart;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    SALogDebug(@"%@ application did enter background", self);

    // 防止主动触发 UIApplicationDidEnterBackgroundNotification
    if (![notification.object isKindOfClass:[UIApplication class]]) {
        return;
    }

    UIApplication *application = (UIApplication *)notification.object;
    if (application.applicationState != UIApplicationStateBackground) {
        return;
    }

    self.state = SAAppLifecycleStateEnd;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    SALogDebug(@"applicationWillTerminateNotification");

    self.state = SAAppLifecycleStateTerminate;
}
#endif

@end

