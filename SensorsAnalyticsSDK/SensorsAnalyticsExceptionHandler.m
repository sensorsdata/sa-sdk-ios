//
//  SensorsAnalyticsExceptionHandler.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/5/26.
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


#import "SensorsAnalyticsExceptionHandler.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"

#if defined(SENSORS_ANALYTICS_CRASH_SLIDEADDRESS)
#import <mach-o/dyld.h>
#endif

static NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";

static volatile int32_t UncaughtExceptionCount = 0;
static const int32_t UncaughtExceptionMaximum = 10;

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@interface SensorsAnalyticsExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, unsafe_unretained) struct sigaction *prev_signal_handlers;
@property (nonatomic, strong) NSHashTable *sensorsAnalyticsSDKInstances;

@end

@implementation SensorsAnalyticsExceptionHandler

+ (instancetype)sharedHandler {
    static SensorsAnalyticsExceptionHandler *gSharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gSharedHandler = [[SensorsAnalyticsExceptionHandler alloc] init];
    });
    return gSharedHandler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create a hash table of weak pointers to SensorsAnalytics instances
        _sensorsAnalyticsSDKInstances = [NSHashTable weakObjectsHashTable];
        
        _prev_signal_handlers = calloc(NSIG, sizeof(struct sigaction));
        
        // Install our handler
        [self setupHandlers];
    }
    return self;
}

- (void)dealloc {
    free(_prev_signal_handlers);
}

- (void)setupHandlers {
    _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&SAHandleException);
    
    struct sigaction action;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = &SASignalHandler;
    int signals[] = {SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        struct sigaction prev_action;
        int err = sigaction(signals[i], &action, &prev_action);
        if (err == 0) {
            char *address_action = (char *)&prev_action;
            char *address_signal = (char *)(_prev_signal_handlers + signals[i]);
            strlcpy(address_signal, address_action, sizeof(prev_action));
        } else {
            SALog(@"Errored while trying to set up sigaction for signal %d", signals[i]);
        }
    }
}

- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance {
    NSParameterAssert(instance != nil);
    if (![self.sensorsAnalyticsSDKInstances containsObject:instance]) {
        [self.sensorsAnalyticsSDKInstances addObject:instance];
    }
}

static void SASignalHandler(int crashSignal, struct __siginfo *info, void *context) {
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedHandler];
    
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount <= UncaughtExceptionMaximum) {
        NSDictionary *userInfo = @{UncaughtExceptionHandlerSignalKey: @(crashSignal)};
        NSString *reason;
        @try {
            reason = [NSString stringWithFormat:@"Signal %d was raised.", crashSignal];
        } @catch(NSException *exception) {
            //ignored
        }

        @try {
            NSException *exception = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                             reason:reason
                                                           userInfo:userInfo];

            [handler sa_handleUncaughtException:exception];
        } @catch(NSException *exception) {

        }
    }
    
    struct sigaction prev_action = handler.prev_signal_handlers[crashSignal];
    if (prev_action.sa_flags & SA_SIGINFO) {
        if (prev_action.sa_sigaction) {
            prev_action.sa_sigaction(crashSignal, info, context);
        }
    } else if (prev_action.sa_handler) {
        prev_action.sa_handler(crashSignal);
    }
}

static void SAHandleException(NSException *exception) {
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedHandler];
    
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount <= UncaughtExceptionMaximum) {
        [handler sa_handleUncaughtException:exception];
    }
    
    if (handler.defaultExceptionHandler) {
        handler.defaultExceptionHandler(exception);
    }
}

- (void) sa_handleUncaughtException:(NSException *)exception {
    // Archive the values for each SensorsAnalytics instance
    @try {
        for (SensorsAnalyticsSDK *instance in self.sensorsAnalyticsSDKInstances) {
            if (instance.configOptions.enableTrackAppCrash) {
                NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
                if ([exception callStackSymbols]) {
#if defined(SENSORS_ANALYTICS_CRASH_SLIDEADDRESS)
                    long slide_address = [SensorsAnalyticsExceptionHandler sa_computeImageSlide];
                    [properties setValue:[NSString stringWithFormat:@"Exception Reason:%@\nSlide_Address:%lx\nException Stack:%@", [exception reason], slide_address, [exception callStackSymbols]] forKey:@"app_crashed_reason"];
#else
                    [properties setValue:[NSString stringWithFormat:@"Exception Reason:%@\nException Stack:%@", [exception reason], [exception callStackSymbols]] forKey:@"app_crashed_reason"];
#endif
                } else {
                    [properties setValue:[NSString stringWithFormat:@"%@ %@", [exception reason], [NSThread callStackSymbols]] forKey:@"app_crashed_reason"];
                }
                [instance track:SA_EVENT_NAME_APP_CRASHED withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
            }
            if (![instance isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd]) {
                sensorsdata_dispatch_main_safe_sync(^{
                    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
                        [instance track:@"$AppEnd" withTrackType:SensorsAnalyticsTrackTypeAuto];
                    }
                });
            }
            // 阻塞当前线程，完成 serialQueue 中数据相关的任务
            sensorsdata_dispatch_safe_sync(instance.serialQueue, ^{});
        }
        SALog(@"Encountered an uncaught exception. All SensorsAnalytics instances were archived.");
    } @catch(NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}

#if defined(SENSORS_ANALYTICS_CRASH_SLIDEADDRESS)
/** 增加 crash slideAdress 采集支持
 *  @return the slide of this binary image
 */
+ (long) sa_computeImageSlide {
    long slide = -1;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (_dyld_get_image_header(i)->filetype == MH_EXECUTE) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    return slide;
}
#endif

@end

