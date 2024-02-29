//
// UIView+SensorsAnalytics.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
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

#import "UIView+SensorsAnalytics.h"
#import "SAWeakPropertyContainer.h"
#include <objc/runtime.h>

static void *const kSASensorsAnalyticsViewIDKey = (void *)&kSASensorsAnalyticsViewIDKey;
static void *const kSASensorsAnalyticsIgnoreViewKey = (void *)&kSASensorsAnalyticsIgnoreViewKey;
static void *const kSASensorsAnalyticsAutoTrackAfterSendActionKey = (void *)&kSASensorsAnalyticsAutoTrackAfterSendActionKey;
static void *const kSASensorsAnalyticsViewPropertiesKey = (void *)&kSASensorsAnalyticsViewPropertiesKey;
static void *const kSASensorsAnalyticsImageNameKey = (void *)&kSASensorsAnalyticsImageNameKey;

@implementation UIView (SensorsAnalytics)

//viewID
- (NSString *)sensorsAnalyticsViewID {
    return objc_getAssociatedObject(self, kSASensorsAnalyticsViewIDKey);
}

- (void)setSensorsAnalyticsViewID:(NSString *)sensorsAnalyticsViewID {
    objc_setAssociatedObject(self, kSASensorsAnalyticsViewIDKey, sensorsAnalyticsViewID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

//ignoreView
- (BOOL)sensorsAnalyticsIgnoreView {
    return [objc_getAssociatedObject(self, kSASensorsAnalyticsIgnoreViewKey) boolValue];
}

- (void)setSensorsAnalyticsIgnoreView:(BOOL)sensorsAnalyticsIgnoreView {
    objc_setAssociatedObject(self, kSASensorsAnalyticsIgnoreViewKey, [NSNumber numberWithBool:sensorsAnalyticsIgnoreView], OBJC_ASSOCIATION_ASSIGN);
}

//afterSendAction
- (BOOL)sensorsAnalyticsAutoTrackAfterSendAction {
    return [objc_getAssociatedObject(self, kSASensorsAnalyticsAutoTrackAfterSendActionKey) boolValue];
}

- (void)setSensorsAnalyticsAutoTrackAfterSendAction:(BOOL)sensorsAnalyticsAutoTrackAfterSendAction {
    objc_setAssociatedObject(self, kSASensorsAnalyticsAutoTrackAfterSendActionKey, [NSNumber numberWithBool:sensorsAnalyticsAutoTrackAfterSendAction], OBJC_ASSOCIATION_ASSIGN);
}

//viewProperty
- (NSDictionary *)sensorsAnalyticsViewProperties {
    return objc_getAssociatedObject(self, kSASensorsAnalyticsViewPropertiesKey);
}

- (void)setSensorsAnalyticsViewProperties:(NSDictionary *)sensorsAnalyticsViewProperties {
    objc_setAssociatedObject(self, kSASensorsAnalyticsViewPropertiesKey, sensorsAnalyticsViewProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<SAUIViewAutoTrackDelegate>)sensorsAnalyticsDelegate {
    SAWeakPropertyContainer *container = objc_getAssociatedObject(self, @"sensorsAnalyticsDelegate");
    return container.weakProperty;
}

- (void)setSensorsAnalyticsDelegate:(id<SAUIViewAutoTrackDelegate>)sensorsAnalyticsDelegate {
    SAWeakPropertyContainer *container = [SAWeakPropertyContainer containerWithWeakProperty:sensorsAnalyticsDelegate];
    objc_setAssociatedObject(self, @"sensorsAnalyticsDelegate", container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIImage (SensorsAnalytics)

- (NSString *)sensorsAnalyticsImageName {
    return objc_getAssociatedObject(self, kSASensorsAnalyticsImageNameKey);
}

- (void)setSensorsAnalyticsImageName:(NSString *)sensorsAnalyticsImageName {
    objc_setAssociatedObject(self, kSASensorsAnalyticsImageNameKey, sensorsAnalyticsImageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)sensorsAnalyticsAssetName {
    return [[self imageAsset] valueForKey:@"assetName"];
}

@end
