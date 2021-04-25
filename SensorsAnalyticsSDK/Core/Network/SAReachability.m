//
// SAReachability.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/1/19.
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

#import "SAReachability.h"
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import "SALog.h"

typedef NS_ENUM(NSInteger, SAReachabilityStatus) {
    SAReachabilityStatusNotReachable = 0,
    SAReachabilityStatusViaWiFi = 1,
    SAReachabilityStatusViaWWAN = 2,
};

typedef void (^SAReachabilityStatusCallback)(SAReachabilityStatus status);

static SAReachabilityStatus SAReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // The target host is not reachable.
        return SAReachabilityStatusNotReachable;
    }

    SAReachabilityStatus returnValue = SAReachabilityStatusNotReachable;

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = SAReachabilityStatusViaWiFi;
    }

    if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0) {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = SAReachabilityStatusViaWiFi;
        }
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        returnValue = SAReachabilityStatusViaWWAN;
    }

    return returnValue;
}

static void SAPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, SAReachabilityStatusCallback block) {
    SAReachabilityStatus status = SAReachabilityStatusForFlags(flags);
    if (block) {
        block(status);
    }
}

static void SAReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    SAPostReachabilityStatusChange(flags, (__bridge SAReachabilityStatusCallback)info);
}

static const void * SAReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void SAReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface SAReachability ()

@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (atomic, assign) SAReachabilityStatus reachabilityStatus;

@end

@implementation SAReachability

#pragma mark - Life Cycle

+ (instancetype)sharedInstance {
    static SAReachability *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self reachabilityInstance];
    });

    return sharedInstance;
}

+ (instancetype)reachabilityInstance {
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&address);
    SAReachability *reachabilityInstance = [[self alloc] initWithReachability:reachability];

    if (reachability != NULL) {
        CFRelease(reachability);
    }

    return reachabilityInstance;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (self) {
        if (reachability != NULL) {
            _networkReachability = CFRetain(reachability);
        }

        self.reachabilityStatus = SAReachabilityStatusNotReachable;
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];

    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark - Public Methods

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    SAReachabilityStatusCallback callback = ^(SAReachabilityStatus status) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        strongSelf.reachabilityStatus = status;
    };

    // 设置网络状态变化的回调
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, SAReachabilityRetainCallback, SAReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, SAReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    // 获取网络状态
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
        SAPostReachabilityStatusChange(flags, callback);
    }
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.reachabilityStatus == SAReachabilityStatusViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.reachabilityStatus == SAReachabilityStatusViaWiFi;
}

@end
