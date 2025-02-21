//
// SAAppTracker.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/5/20.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppTracker.h"
#import "SATrackEventObject.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SALog.h"
#import "SAConstants+Private.h"
#import "SAJSONUtil.h"
#import "SAValidator.h"
#import "SAAutoTrackResources.h"

@implementation SAAppTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignored = NO;
        _passively = NO;
        _ignoredViewControllers = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)eventId {
    return nil;
}

- (void)trackAutoTrackEventWithProperties:(NSDictionary *)properties {
    SAAutoTrackEventObject *object = [[SAAutoTrackEventObject alloc] initWithEventId:[self eventId]];

    [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:properties];
}

- (void)trackPresetEventWithProperties:(NSDictionary *)properties {
    SAPresetEventObject *object  = [[SAPresetEventObject alloc] initWithEventId:[self eventId]];

    [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:properties];
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    return YES;
}

- (void)ignoreAutoTrackViewControllers:(NSArray<Class> *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [self.ignoredViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    if (viewController == nil) {
        return NO;
    }

    Class viewControllerClass = [viewController class];
    return [self.ignoredViewControllers containsObject:viewControllerClass];
}

- (NSDictionary *)autoTrackViewControllerBlackList {
    return [SAAutoTrackResources viewControllerBlacklist];
}

- (BOOL)isViewController:(UIViewController *)viewController inBlackList:(NSDictionary *)blackList {
    if (!viewController || ![SAValidator isValidDictionary:blackList]) {
        return NO;
    }

    for (NSString *publicClass in blackList[@"public"]) {
        if ([viewController isKindOfClass:NSClassFromString(publicClass)]) {
            return YES;
        }
    }
    return [(NSArray *)blackList[@"private"] containsObject:NSStringFromClass(viewController.class)];
}

@end
