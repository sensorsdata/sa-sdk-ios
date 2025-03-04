//
// SAExceptionManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/6/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAExceptionManager.h"
#import "SensorsAnalyticsSDK.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"
#import "SALog.h"
#import "SAConfigOptions+Exception.h"

#include <libkern/OSAtomic.h>
#include <execinfo.h>

static NSString * const kSASignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const kSASignalKey = @"UncaughtExceptionHandlerSignalKey";

static volatile int32_t kSAExceptionCount = 0;
static const int32_t kSAExceptionMaximum = 10;

static NSString * const kSAAppCrashedReason = @"app_crashed_reason";

@interface SAExceptionManager ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, unsafe_unretained) struct sigaction *prev_signal_handlers;

@end

@implementation SAExceptionManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAExceptionManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAExceptionManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        _prev_signal_handlers = calloc(NSIG, sizeof(struct sigaction));

        [self setupExceptionHandler];
    }
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions NS_EXTENSION_UNAVAILABLE("Exception not supported for iOS extensions.") {
    _configOptions = configOptions;
    self.enable = configOptions.enableTrackAppCrash;
}

- (void)dealloc {
    free(_prev_signal_handlers);
}

- (void)setupExceptionHandler {
    _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&SAHandleException);

    struct sigaction action;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = &SASignalHandler;
    int signals[] = {SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        struct sigaction prev_action;
        int err = sigaction(signals[i], &action, &prev_action);
        if (err == 0) {
            char *address_action = (char *)&prev_action;
            char *address_signal = (char *)(_prev_signal_handlers + signals[i]);
            strlcpy(address_signal, address_action, sizeof(prev_action));
        } else {
            SALogError(@"Errored while trying to set up sigaction for signal %d", signals[i]);
        }
    }
}

#pragma mark - Handler

static void SASignalHandler(int crashSignal, struct __siginfo *info, void *context) {
    int32_t exceptionCount = OSAtomicIncrement32(&kSAExceptionCount);
    if (exceptionCount <= kSAExceptionMaximum) {
        NSDictionary *userInfo = @{kSASignalKey: @(crashSignal)};
        NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.", crashSignal];
        NSException *exception = [NSException exceptionWithName:kSASignalExceptionName
                                                         reason:reason
                                                       userInfo:userInfo];

        [SAExceptionManager.defaultManager handleUncaughtException:exception];
    }

    struct sigaction prev_action = SAExceptionManager.defaultManager.prev_signal_handlers[crashSignal];
    if (prev_action.sa_flags & SA_SIGINFO) {
        if (prev_action.sa_sigaction) {
            prev_action.sa_sigaction(crashSignal, info, context);
        }
    } else if (prev_action.sa_handler &&
               prev_action.sa_handler != SIG_IGN) {
        // SIG_IGN 表示忽略信号
        prev_action.sa_handler(crashSignal);
    }
}

static void SAHandleException(NSException *exception) {
    int32_t exceptionCount = OSAtomicIncrement32(&kSAExceptionCount);
    if (exceptionCount <= kSAExceptionMaximum) {
        [SAExceptionManager.defaultManager handleUncaughtException:exception];
    }

    if (SAExceptionManager.defaultManager.defaultExceptionHandler) {
        SAExceptionManager.defaultManager.defaultExceptionHandler(exception);
    }
}

- (void)handleUncaughtException:(NSException *)exception {
    if (!self.enable) {
        return;
    }
    @try {
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (exception.callStackSymbols) {
            properties[kSAAppCrashedReason] = [NSString stringWithFormat:@"Exception Reason:%@\nException Stack:%@", exception.reason, [exception.callStackSymbols componentsJoinedByString:@"\n"]];
        } else {
            properties[kSAAppCrashedReason] = [NSString stringWithFormat:@"%@ %@", exception.reason, [NSThread.callStackSymbols componentsJoinedByString:@"\n"]];
        }
        SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppCrashed];

        [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:properties];

        //触发页面浏览时长事件
        [[SAModuleManager sharedInstance] trackPageLeaveWhenCrashed];

        // 触发退出事件
        [SAModuleManager.sharedInstance trackAppEndWhenCrashed];

        // 阻塞当前线程，完成 serialQueue 中数据相关的任务
        sensorsdata_dispatch_safe_sync(SensorsAnalyticsSDK.sdkInstance.serialQueue, ^{});
        SALogError(@"Encountered an uncaught exception. All SensorsAnalytics instances were archived.");
    } @catch(NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
}

@end
