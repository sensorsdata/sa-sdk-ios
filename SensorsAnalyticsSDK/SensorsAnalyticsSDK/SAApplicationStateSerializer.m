//
//  SAApplicationStateSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

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

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index {
    UIImage *image = nil;
    
    UIWindow *window = [self windowAtIndex:index];
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, window.screen.scale);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
                SAError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
        } else {
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
#else
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (UIWindow *)windowAtIndex:(NSUInteger)index {
    NSParameterAssert(index < [_application.windows count]);
    return _application.windows[index];
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index {
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }
    
    return @{};
}

@end
