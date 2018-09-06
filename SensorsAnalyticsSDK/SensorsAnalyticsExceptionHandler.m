//
//  SensorsAnalyticsExceptionHandler.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/5/26.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "SensorsAnalyticsExceptionHandler.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

#if defined(SENSORS_ANALYTICS_CRASH_SLIDEADDRESS)
#import <mach-o/dyld.h>
#endif

static NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";

static volatile int32_t UncaughtExceptionCount = 0;
static const int32_t UncaughtExceptionMaximum = 10;

@interface SensorsAnalyticsExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, unsafe_unretained) struct sigaction *prev_signal_handlers;
@property (nonatomic, strong) NSHashTable *sensorsAnalyticsSDKInstances;

@end

@interface SensorsAnalyticsSDK()
@property (nonatomic, strong) dispatch_queue_t serialQueue;
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
            memcpy(_prev_signal_handlers + signals[i], &prev_action, sizeof(prev_action));
        } else {
            SALog(@"Errored while trying to set up sigaction for signal %d", signals[i]);
        }
    }
}

- (void)addSensorsAnalyticsInstance:(SensorsAnalyticsSDK *)instance {
    NSParameterAssert(instance != nil);
    
    [self.sensorsAnalyticsSDKInstances addObject:instance];
}

void SASignalHandler(int crashSignal, struct __siginfo *info, void *context) {
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

void SAHandleException(NSException *exception) {
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
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            @try {
                if ([exception callStackSymbols]) {
#if defined(SENSORS_ANALYTICS_CRASH_SLIDEADDRESS)
                    long slide_address = [SensorsAnalyticsExceptionHandler sa_computeImageSlide];
                    [properties setValue:[NSString stringWithFormat:@"Exception Reason:%@\nSlide_Address:%lx\nException Stack:%@", [exception reason], slide_address,[exception callStackSymbols]] forKey:@"app_crashed_reason"];
                    
#else
                    [properties setValue:[NSString stringWithFormat:@"Exception Reason:%@\nException Stack:%@", [exception reason], [exception callStackSymbols]] forKey:@"app_crashed_reason"];
                    
#endif
                } else {
                    [properties setValue:[NSString stringWithFormat:@"%@ %@", [exception reason], [NSThread callStackSymbols]] forKey:@"app_crashed_reason"];
                }
            } @catch(NSException *exception) {
                SAError(@"%@ error: %@", self, exception);
            }
            [instance track:@"AppCrashed" withProperties:properties];
            if (![instance isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppEnd]) {
                [instance track:@"$AppEnd"];
            }
            dispatch_sync(instance.serialQueue, ^{

            });
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

