//
// SAApplication.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/9/8.
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

#import "SAApplication.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@implementation SAApplication

+ (id)sharedApplication {
#if TARGET_OS_IOS
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
