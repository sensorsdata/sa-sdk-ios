//
// SAAppPageLeaveTracker.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/7/19.
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

#import "SAAppPageLeaveTracker.h"
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK+SAAutoTrack.h"
#import "SAConstants+Private.h"
#import "SAConstants+Private.h"
#import "SAAppLifecycle.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAutoTrackManager.h"

@implementation SAPageLeaveObject

@end

@interface SAAppPageLeaveTracker ()

@property (nonatomic, copy) NSString *referrerURL;

@end

@implementation SAAppPageLeaveTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kSAAppLifecycleStateWillChangeNotification object:nil];
    }
    return self;
}

- (NSString *)eventId {
    return kSAEventNameAppPageLeave;
}

- (void)trackEvents {
    [self.pageLeaveObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SAPageLeaveObject * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!obj.viewController) {
            return;
        }
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval startTimestamp = obj.timestamp;
        NSMutableDictionary *tempProperties = [[NSMutableDictionary alloc] initWithDictionary:[self propertiesWithViewController:obj.viewController]];
        NSTimeInterval duration = (currentTimestamp - startTimestamp) < 24 * 60 * 60 ? (currentTimestamp - startTimestamp) : 0;
        tempProperties[kSAEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", duration] floatValue]);
        if (obj.referrerURL) {
            tempProperties[kSAEventPropertyScreenReferrerUrl] = obj.referrerURL;
        }
        [self trackWithProperties:[tempProperties copy]];
    }];
}

- (void)trackPageEnter:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    if (self.pageLeaveObjects[address]) {
        return;
    }
    SAPageLeaveObject *object = [[SAPageLeaveObject alloc] init];
    object.timestamp = [[NSDate date] timeIntervalSince1970];
    object.viewController = viewController;
    NSString *currentURL;
    if ([viewController conformsToProtocol:@protocol(SAScreenAutoTracker)] && [viewController respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)viewController;
        currentURL = [screenAutoTrackerController getScreenUrl];
    }
    currentURL = [currentURL isKindOfClass:NSString.class] ? currentURL : NSStringFromClass(viewController.class);
    object.referrerURL = [self referrerURLWithURL:currentURL eventProperties:[SAAutoTrackUtils propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)viewController]];
    self.pageLeaveObjects[address] = object;
}

- (void)trackPageLeave:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    SAPageLeaveObject *object = self.pageLeaveObjects[address];
    if (!object) {
        return;
    }
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval startTimestamp = object.timestamp;
    NSMutableDictionary *tempProperties = [self propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)(object.viewController)];
    NSTimeInterval duration = (currentTimestamp - startTimestamp) < 24 * 60 * 60 ? (currentTimestamp - startTimestamp) : 0;
    tempProperties[kSAEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", duration] floatValue]);
    if (object.referrerURL) {
        tempProperties[kSAEventPropertyScreenReferrerUrl] = object.referrerURL;
    }
    [self trackWithProperties:tempProperties];
    [self.pageLeaveObjects removeObjectForKey:address];
}

- (void)trackWithProperties:(NSDictionary *)properties {
    SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSAEventNameAppPageLeave];
    [SensorsAnalyticsSDK.sharedInstance asyncTrackEventObject:object properties:properties];
}

- (void)appLifecycleStateWillChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    SAAppLifecycleState newState = [userInfo[kSAAppLifecycleNewStateKey] integerValue];
    // 冷（热）启动
    if (newState == SAAppLifecycleStateStart) {
        [self.pageLeaveObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SAPageLeaveObject * _Nonnull obj, BOOL * _Nonnull stop) {
            obj.timestamp = [[NSDate date] timeIntervalSince1970];
        }];
        return;
    }
    // 退出
    if (newState == SAAppLifecycleStateEnd) {
        [self trackEvents];
    }
}

- (NSMutableDictionary *)propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)viewController {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    NSDictionary *autoTrackProperties = [SAAutoTrackUtils propertiesWithViewController:viewController];
    [eventProperties addEntriesFromDictionary:autoTrackProperties];
    if (eventProperties[kSAEventPropertyScreenUrl]) {
        return eventProperties;
    }
    NSString *currentURL;
    if ([viewController conformsToProtocol:@protocol(SAScreenAutoTracker)] && [viewController respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<SAScreenAutoTracker> *screenAutoTrackerController = (UIViewController<SAScreenAutoTracker> *)viewController;
        currentURL = [screenAutoTrackerController getScreenUrl];
    }
    currentURL = [currentURL isKindOfClass:NSString.class] ? currentURL : NSStringFromClass(viewController.class);
    eventProperties[kSAEventPropertyScreenUrl] = currentURL;
    return eventProperties;
}

- (NSString *)referrerURLWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties {
    NSString *referrerURL = self.referrerURL;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];

    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[kSAEventPropertyScreenUrl]) {
        newProperties[kSAEventPropertyScreenUrl] = currentURL;
    }
    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[kSAEventPropertyScreenReferrerUrl]) {
        newProperties[kSAEventPropertyScreenReferrerUrl] = referrerURL;
    }
    // $referrer 内容以最终页面浏览事件中的 $url 为准
    self.referrerURL = newProperties[kSAEventPropertyScreenUrl];

    return newProperties[kSAEventPropertyScreenReferrerUrl];
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    NSDictionary *autoTrackBlackList = [self autoTrackViewControllerBlackList];
    NSDictionary *appViewScreenBlackList = autoTrackBlackList[kSAEventNameAppViewScreen];
    if ([self isViewController:viewController inBlackList:appViewScreenBlackList]) {
        return NO;
    }
    if ([SAAutoTrackManager.defaultManager.configOptions.ignoredPageLeaveClasses containsObject:[viewController class]]) {
        return NO;
    }
    if (SAAutoTrackManager.defaultManager.configOptions.enableTrackChildPageLeave ||
        !viewController.parentViewController ||
        [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
        [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
        [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
        return YES;
    }
    return NO;
}

- (NSMutableDictionary<NSString *,SAPageLeaveObject *> *)pageLeaveObjects {
    if (!_pageLeaveObjects) {
        _pageLeaveObjects = [[NSMutableDictionary alloc] init];
    }
    return _pageLeaveObjects;
}

@end
