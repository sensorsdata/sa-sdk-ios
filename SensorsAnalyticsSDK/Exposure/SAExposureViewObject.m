//
// SAExposureView.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
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

#import "SAExposureViewObject.h"
#import "SensorsAnalyticsSDK.h"
#import "SAModuleManager.h"
#import "SAExposureData+Private.h"
#import "SAExposureConfig+Private.h"
#import "SAValidator.h"
#import "SAUIProperties.h"
#import "SAConstants+Private.h"
#import "UIView+ExposureListener.h"
#import "SALog.h"
#import "UIView+SAInternalProperties.h"
#import "NSObject+SAKeyValueObserver.h"

static void * const kSAExposureViewFrameContext = (void*)&kSAExposureViewFrameContext;
static void * const kSAExposureViewAlphaContext = (void*)&kSAExposureViewAlphaContext;
static void * const kSAExposureViewHiddenContext = (void*)&kSAExposureViewHiddenContext;
static void * const kSAExposureViewContentOffsetContext = (void*)&kSAExposureViewContentOffsetContext;

@implementation SAExposureViewObject

- (instancetype)initWithView:(UIView *)view exposureData:(SAExposureData *)exposureData {
    self = [super init];
    if (self) {
        _view = view;
        _exposureData = exposureData;
        _state = SAExposureViewStateInvisible;
        _type = SAExposureViewTypeNormal;
        _lastExposure = 0;
        __weak typeof(self) weakSelf = self;
        _timer = [[SAExposureTimer alloc] initWithDuration:exposureData.config.stayDuration completeBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf triggerExposure];
            });
        }];
    }
    return self;
}

- (void)addExposureViewObserver {
    [self.view sensorsdata_addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kSAExposureViewFrameContext];
    [self.view sensorsdata_addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kSAExposureViewAlphaContext];
    [self.view sensorsdata_addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kSAExposureViewHiddenContext];
}

- (void)clear {
    [self.timer invalidate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kSAExposureViewFrameContext) {
        [self observeFrameChange:change];
    } else if (context == kSAExposureViewAlphaContext) {
        [self observeAlphaChange:change];
    } else if (context == kSAExposureViewHiddenContext) {
        [self observeHiddenChange:change];
    } else if (context == kSAExposureViewContentOffsetContext) {
        [self observeContentOffsetChange:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)observeFrameChange:(NSDictionary *)change {
    NSValue *newValue = change[NSKeyValueChangeNewKey];
    NSValue *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSValue class]] || ![oldValue isKindOfClass:[NSValue class]]) {
        return;
    }
    if ([newValue isEqualToValue:oldValue]) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        if (self.state == SAExposureViewStateInvisible || self.state == SAExposureViewStateExposing) {
            return;
        }
    }
    [self exposureConditionCheck];
}

- (void)observeAlphaChange:(NSDictionary *)change {
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    NSNumber *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSNumber class]] || ![oldValue isKindOfClass:[NSNumber class]]) {
        return;
    }
    if ([newValue isEqualToNumber:oldValue]) {
        return;
    }
    float oldAlphaValue = oldValue.floatValue;
    float newAlphaValue = newValue.floatValue;
    if (oldAlphaValue > 0.01 && newAlphaValue <= 0.01) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (oldAlphaValue <= 0.01 && newAlphaValue > 0.01) {
        if (self.lastAreaRate >= self.exposureData.config.areaRate) {
            [self.timer start];
            self.state = SAExposureViewStateVisible;
            return;
        }
        [self exposureConditionCheck];
        return;
    }
}

- (void)observeHiddenChange:(NSDictionary *)change {
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    NSNumber *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSNumber class]] || ![oldValue isKindOfClass:[NSNumber class]]) {
        return;
    }
    if ([newValue isEqualToNumber:oldValue]) {
        return;
    }
    BOOL newHiddenValue = [newValue boolValue];
    BOOL oldHiddenValue = [oldValue boolValue];
    if (oldHiddenValue && !newHiddenValue) {
        if (self.lastAreaRate >= self.exposureData.config.areaRate) {
            [self.timer start];
            self.state = SAExposureViewStateVisible;
            return;
        }
        [self exposureConditionCheck];
        return;
    }
    if (!oldHiddenValue && newHiddenValue) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
    }
}

- (void)observeContentOffsetChange:(NSDictionary *)change {
    NSValue *newValue = change[NSKeyValueChangeNewKey];
    NSValue *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSValue class]] || ![oldValue isKindOfClass:[NSValue class]]) {
        return;
    }
    if ([newValue isEqualToValue:oldValue]) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        if (self.state == SAExposureViewStateInvisible || self.state == SAExposureViewStateExposing) {
            return;
        }
    }
    [self exposureConditionCheck];
}

- (void)exposureConditionCheck {
    if (!self.view) {
        return;
    }

    if (!self.exposureData.config.repeated && self.lastExposure > 0) {
        return;
    }

    if ([self.view isKindOfClass:[UIWindow class]] && self.view != [self topWindow]) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (!self.view.window) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.view.isHidden) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.view.alpha <= 0.01) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (CGRectEqualToRect(self.view.frame, CGRectZero)) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }

    CGRect visibleRect = CGRectZero;
    if ([self.view isKindOfClass:[UIWindow class]]) {
        visibleRect = CGRectIntersection(self.view.frame, [UIScreen mainScreen].bounds);
    } else {
        CGRect viewToWindowRect = [self.view convertRect:self.view.bounds toView:self.view.window];
        CGRect windowRect = self.view.window.bounds;
        CGRect viewVisableRect = CGRectIntersection(viewToWindowRect, windowRect);
        visibleRect = viewVisableRect;
        if (self.scrollView) {
            CGRect scrollViewToWindowRect = [self.scrollView convertRect:self.scrollView.bounds toView:self.scrollView.window];
            CGRect scrollViewVisableRect = CGRectIntersection(scrollViewToWindowRect, windowRect);
            visibleRect = CGRectIntersection(viewVisableRect, scrollViewVisableRect);
        }
    }

    if (CGRectIsNull(visibleRect)) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        self.lastAreaRate = 0;
        return;
    }
    CGFloat visableRate = (visibleRect.size.width * visibleRect.size.height) / (self.view.bounds.size.width * self.view.bounds.size.height);
    self.lastAreaRate = visableRate;
    if (visableRate <= 0) {
        self.state = SAExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.state == SAExposureViewStateExposing) {
        return;
    }
    // convert to string to compare float number
    NSComparisonResult result = [[NSString stringWithFormat:@"%.2f",visableRate] compare:[NSString stringWithFormat:@"%.2f",self.exposureData.config.areaRate]];

    if (result != NSOrderedAscending) {
        [self.timer start];
    } else {
        [self.timer stop];
    }
}

- (UIWindow *)topWindow NS_EXTENSION_UNAVAILABLE("Exposure not supported for iOS extensions.") {
    NSArray<UIWindow *> *windows;
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        windows = scene.windows;
    } else {
        windows = UIApplication.sharedApplication.windows;
    }

    if (!windows || windows.count < 1) {
        return nil;
    }

    NSArray *sortedWindows = [windows sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        UIWindow *window1 = obj1;
        UIWindow *window2 = obj2;
        if (window1.windowLevel < window2.windowLevel) {
            return NSOrderedAscending;
        } else if (window1.windowLevel == window2.windowLevel) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    return sortedWindows.lastObject;
}

- (void)triggerExposure {
    [self.timer stop];
    BOOL shouldExpose = YES;
    if (self.exposureData.exposureListener && [self.exposureData.exposureListener respondsToSelector:@selector(shouldExpose:withData:)]) {
        shouldExpose = [self.exposureData.exposureListener shouldExpose:self.view withData:self.exposureData];
    }
    if (!shouldExpose) {
        SALogInfo(@"Exposure for view: %@ had been canceld due to shouldExpose return false", self.view);
        return;
    }
    self.state = SAExposureViewStateExposing;
    self.lastExposure = [[NSDate date] timeIntervalSince1970];
    //track event
    if (self.view == nil) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        [self trackEventWithScrollView:self.scrollView cell:self.view atIndexPath:self.indexPath];
    } else {
        [self trackEventWithView:self.view properties:nil];
    }
    if (self.exposureData.exposureListener && [self.exposureData.exposureListener respondsToSelector:@selector(didExpose:withData:)]) {
        [self.exposureData.exposureListener didExpose:self.view withData:self.exposureData];
    }
}

- (void)trackEventWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    if (view == nil) {
        return;
    }
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc]init];
    [eventProperties addEntriesFromDictionary:[SAUIProperties propertiesWithView:view viewController:self.viewController]];
    if ([SAValidator isValidDictionary:properties]) {
        [eventProperties addEntriesFromDictionary:properties];
    }
    if ([SAValidator isValidDictionary:self.exposureData.properties]) {
        [eventProperties addEntriesFromDictionary:self.exposureData.properties];
    }
    if ([SAValidator isValidDictionary:self.exposureData.updatedProperties]) {
        [eventProperties addEntriesFromDictionary:self.exposureData.updatedProperties];
    }
    NSString *elementPath = [SAUIProperties elementPathForView:view atViewController:self.viewController];
    eventProperties[kSAEventPropertyElementPath] = elementPath;
    [[SensorsAnalyticsSDK sharedInstance] track:self.exposureData.event withProperties:eventProperties];
}

- (void)trackEventWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:[SAUIProperties propertiesWithScrollView:scrollView cell:cell]];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [SAUIProperties propertiesWithAutoTrackDelegate:scrollView andIndexPath:indexPath];
    if ([dic isKindOfClass:[NSDictionary class]]) {
        [properties addEntriesFromDictionary:dic];
    }
    [self trackEventWithView:cell properties:properties];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) {
        return;
    }
    [scrollView sensorsdata_addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kSAExposureViewContentOffsetContext];
    _scrollView = scrollView;
}

- (void)setView:(UIView *)view {
    if (_view == view) {
        return;
    }
    _view = view;
    [self addExposureViewObserver];
}

- (UIViewController *)viewController {
    UIResponder *nextResponser = self.view;
    while ((nextResponser = nextResponser.nextResponder)) {
        UIResponder *viewController = nextResponser;
        if ([viewController isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)viewController;
        }
    }
    return nil;
}

- (void)findNearbyScrollView {
    if (self.scrollView) {
        return;
    }
    if (![self.view isKindOfClass:[UITableViewCell class]] && ![self.view isKindOfClass:[UICollectionViewCell class]]) {
        self.scrollView = self.view.sensorsdata_nearbyScrollView;
    }
}

@end

