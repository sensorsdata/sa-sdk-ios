//
// SAApplication.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAApplication.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#endif

@implementation SAApplication

+ (id)sharedApplication {
#if TARGET_OS_IOS || TARGET_OS_TV
    Class applicationClass = NSClassFromString(@"UIApplication");
    if (!applicationClass) {
        return nil;
    }
    SEL sharedApplicationSEL = NSSelectorFromString(@"sharedApplication");
    if (!sharedApplicationSEL) {
        return nil;
    }
    id (*sharedApplication)(id, SEL) = (id (*)(id, SEL))[applicationClass methodForSelector:sharedApplicationSEL];
    id application = sharedApplication(applicationClass, sharedApplicationSEL);
    return application;
#else
    return nil;
#endif
}

+ (BOOL)isAppExtension {
    NSString *bundlePath = [[NSBundle mainBundle] executablePath];
    if (!bundlePath) {
        return NO;
    }

    return [bundlePath containsString:@".appex/"];
}

@end
