//
//  SAApplicationStateSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
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


#import <QuartzCore/QuartzCore.h>
#import "SAApplicationStateSerializer.h"
#import "SAClassDescription.h"
#import "SALogger.h"
#import "SAObjectIdentityProvider.h"
#import "SAObjectSerializer.h"
#import "SAObjectSerializerConfig.h"

@implementation SAApplicationStateSerializer {
    SAObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application
                      configuration:(SAObjectSerializerConfig *)configuration
             objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    NSParameterAssert(application != nil);
    NSParameterAssert(configuration != nil);
    
    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[SAObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }
    
    return self;
}

- (UIImage *)screenshotImageForWindow:(UIWindow *)window {
    UIImage *image = nil;
    
    UIWindow *mainWindow = [self uiMainWindow:window];
    if (mainWindow && !CGRectEqualToRect(mainWindow.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(mainWindow.bounds.size, YES, mainWindow.screen.scale);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([mainWindow respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            if ([mainWindow drawViewHierarchyInRect:mainWindow.bounds afterScreenUpdates:NO] == NO) {
                SAError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
        } else {
            [mainWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
#else
        [mainWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (UIWindow *)uiMainWindow:(UIWindow *)window {
    if (window != nil) {
        return window;
    }
    return _application.windows[0];
}

- (NSDictionary *)objectHierarchyForWindow:(UIWindow *)window {
    UIWindow *mainWindow = [self uiMainWindow:window];
    if (mainWindow) {
        return [_serializer serializedObjectsWithRootObject:mainWindow];
    }
    
    return @{};
}

@end
