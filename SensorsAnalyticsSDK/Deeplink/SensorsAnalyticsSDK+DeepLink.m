//
// SensorsAnalyticsSDK+DeepLink.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/11.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+DeepLink.h"
#import "SADeepLinkManager.h"
#import "SAConstants+Private.h"
#import "SALog.h"

@implementation SADeepLinkObject

@end

@implementation SensorsAnalyticsSDK (DeepLink)

- (void)setDeeplinkCallback:(void(^)(NSString *_Nullable params, BOOL success, NSInteger appAwakePassedTime))callback {
    if (!callback) {
        return;
    }
    SADeepLinkManager.defaultManager.oldCompletion = ^BOOL(SADeepLinkObject * _Nonnull object) {
        callback(object.params, object.success, object.appAwakePassedTime);
        return NO;
    };
}

- (void)requestDeferredDeepLink:(NSDictionary *)properties {
    [SADeepLinkManager.defaultManager requestDeferredDeepLink:properties];
}

- (void)setDeepLinkCompletion:(BOOL(^)(SADeepLinkObject *obj))completion {
    if (!completion) {
        return;
    }
    SADeepLinkManager.defaultManager.completion = completion;
}

- (void)trackDeepLinkLaunchWithURL:(NSString *)url {
    [[SADeepLinkManager defaultManager] trackDeepLinkLaunchWithURL:url];
}

@end
