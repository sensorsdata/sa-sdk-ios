//
// SAAppInteractTracker.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/10/23.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppInteractTracker.h"
#import "SAAppLifecycle.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "SAStoreManager.h"
#import "SALog.h"
#import "SAIdentifier.h"
#import "SACommonUtility.h"

@interface SAAppInteractTracker ()

@property (nonatomic, assign) BOOL hasInstalledApp;

@end

@implementation SAAppInteractTracker

- (instancetype)init {
    if (self = [super init]) {
        [self addListener];
        _hasInstalledApp = [self isAppInstalled];
    }
    return self;
}

- (void)addListener {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kSAAppLifecycleStateDidChangeNotification object:nil];
}

- (void)removeListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSAAppLifecycleStateDidChangeNotification object:nil];
}

- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    SAAppLifecycleState newState = [sender.userInfo[kSAAppLifecycleNewStateKey] integerValue];
    SAAppLifecycleState oldState = [sender.userInfo[kSAAppLifecycleOldStateKey] integerValue];
    if (!self.awakeFromDeeplink && oldState == SAAppLifecycleStateInit && newState == SAAppLifecycleStateStart) {
        self.awakeFromDeeplink = self.awakeFromDeeplink ?: self.wakeupUrl ? YES : NO;
    }
    if (newState == SAAppLifecycleStateStart) {
        [self trackAppInteract];
        self.awakeFromDeeplink = NO;
        self.hasInstalledApp = [self isAppInstalled];
    }
}

- (BOOL)shouldTrackAppInteract {
    NSTimeInterval lastAppInteractTimeInterval = [[SAStoreManager sharedInstance] doubleForKey:kSAAppInteractEventTimeIntervalKey];
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    if (lastAppInteractTimeInterval >= nowTimeInterval) {
        SALogError(@"Incorrect timeInterval for last AppInteract event");
        return NO;
    }
    if (lastAppInteractTimeInterval == 0) {
        return YES;
    }
    NSDate *lastAppInteractDate = [NSDate dateWithTimeIntervalSince1970:lastAppInteractTimeInterval];
    BOOL inToday = [[NSCalendar currentCalendar] isDateInToday:lastAppInteractDate];
    return !inToday;
}

- (void)trackAppInteract {
    if (![self shouldTrackAppInteract]) {
        return;
    }
    BOOL hasInstalledApp = self.hasInstalledApp;
    BOOL awakeFromDeeplink = self.awakeFromDeeplink;
    [[SensorsAnalyticsSDK sharedInstance] track:kSAAppInteractEventName withProperties:@{kSAEventPropertyHasInstalledApp: @(hasInstalledApp), kSAEventPropertyAwakeFromDeeplink: @(awakeFromDeeplink), kSAEventPropertyInstallSource: [SACommonUtility appInstallSource]}];
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    [[SAStoreManager sharedInstance] setDouble:timestamp forKey:kSAAppInteractEventTimeIntervalKey];
}

- (BOOL)isAppInstalled {
    SAStoreManager *manager = [SAStoreManager sharedInstance];
    return [manager boolForKey:kSAHasTrackInstallationDisableCallback] || [manager boolForKey:kSAHasTrackInstallation];
}

- (void)dealloc {
    [self removeListener];
}

@end
