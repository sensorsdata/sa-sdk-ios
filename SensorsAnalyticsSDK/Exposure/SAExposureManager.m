//
// SAExposureManager.m
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

#import "SAExposureManager.h"
#import "SAConfigOptions+Exposure.h"
#import "SAExposureData+Private.h"
#import "UIView+ExposureIdentifier.h"
#import "SAExposureConfig+Private.h"
#import "SASwizzle.h"
#import "UIView+ExposureListener.h"
#import "UIScrollView+ExposureListener.h"
#import "UIViewController+ExposureListener.h"
#import "SAMethodHelper.h"
#import "SALog.h"


static NSString *const kSAExposureViewMark = @"sensorsdata_exposure_mark";

@implementation SAExposureManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAExposureManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAExposureManager alloc] init];
        [manager addListener];
        [manager swizzleMethods];
    });
    return manager;
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = YES;
}

- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data {
    if (!view) {
        SALogError(@"View to expose should not be nil");
        return;
    }
    if (!data.event || ([data.event isKindOfClass:[NSString class]] && data.event.length == 0)) {
        SALogError(@"Event name should not be empty or nil");
        return;
    }
    if (!data.config) {
        data.config = self.configOptions.exposureConfig;
    }
    __block BOOL exist = NO;
    [self.exposureViewObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAExposureViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.view) {
            [obj clear];
            [self.exposureViewObjects removeObject:obj];
            return;
        }
        if ((!data.exposureIdentifier && obj.view == view) || (data.exposureIdentifier && [obj.exposureData.exposureIdentifier isEqualToString:data.exposureIdentifier])) {
            obj.exposureData = data;
            obj.view = view;
            exist = YES;
            *stop = YES;
        }
    }];
    if (exist) {
        return;
    }
    SAExposureViewObject *exposureViewObject = [[SAExposureViewObject alloc] initWithView:view exposureData:data];
    exposureViewObject.view.sensorsdata_exposureMark = kSAExposureViewMark;
    //get view related items, such as viewController, scrollView, state
    if (![view isKindOfClass:[UITableViewCell class]] && ![view isKindOfClass:[UICollectionViewCell class]]) {
        exposureViewObject.scrollView = (UIScrollView *)[self nearbyScrollViewByView:view];
    }
    [exposureViewObject addExposureViewObserver];
    [self.exposureViewObjects addObject:exposureViewObject];
    [exposureViewObject exposureConditionCheck];
}

- (void)removeExposureView:(UIView *)view withExposureIdentifier:(NSString *)identifier {
    if (!view) {
        return;
    }
    [self.exposureViewObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SAExposureViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.view == view) {
            if (!identifier || [obj.exposureData.exposureIdentifier isEqualToString:identifier]) {
                [obj clear];
                [self.exposureViewObjects removeObject:obj];
            }
            *stop = YES;
        }
    }];
}

- (SAExposureViewObject *)exposureViewWithView:(UIView *)view {
    if (!view) {
        return nil;
    }
    for (SAExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.view != view) {
            continue;
        }
        if (!exposureViewObject.exposureData.exposureIdentifier) {
            return exposureViewObject;
        }
        if (exposureViewObject.exposureData.exposureIdentifier && view.exposureIdentifier && [exposureViewObject.exposureData.exposureIdentifier isEqualToString:view.exposureIdentifier]) {
            return exposureViewObject;
        }
        return nil;
    }
    return nil;
}

- (UIView *)nearbyScrollViewByView:(UIView *)view {
    UIView *superView = view.superview;
    if ([superView isKindOfClass:[UIScrollView class]] || !superView) {
        return superView;
    }
    return [self nearbyScrollViewByView:superView];
}

- (void)addListener {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
}

- (void)swizzleMethods {
    [SAMethodHelper swizzleRespondsToSelector];
    [UIView sa_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(sensorsdata_didMoveToSuperview) error:NULL];
    BOOL isSuccess = [UITableView sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_exposure_setDelegate:) error:NULL];
    [UICollectionView sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_exposure_setDelegate:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_exposure_viewDidAppear:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(sensorsdata_exposure_viewDidDisappear:) error:NULL];
}

- (void)applicationDidEnterBackground {
    for (SAExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.state == SAExposureViewStateExposing || exposureViewObject.state == SAExposureViewStateVisible) {
            exposureViewObject.state = SAExposureViewStateBackgroundInvisible;
            [exposureViewObject.timer stop];
        }
    }
}

- (void)applicationDidBecomeActive {
    for (SAExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.state == SAExposureViewStateBackgroundInvisible) {
            exposureViewObject.state = SAExposureViewStateVisible;
            if (!exposureViewObject.exposureData.config.repeated && exposureViewObject.lastExposure > 0) {
                continue;
            }
            // convert to string to compare float number
            NSComparisonResult result = [[NSString stringWithFormat:@"%.2f",exposureViewObject.lastAreaRate] compare:[NSString stringWithFormat:@"%.2f",exposureViewObject.exposureData.config.areaRate]];
            if (result != NSOrderedAscending) {
                [exposureViewObject.timer start];
            }
        }
    }
}

- (void)windowDidBecomeVisible:(NSNotification *)notification {
    UIWindow *visibleWindow = notification.object;
    if (!visibleWindow) {
        return;
    }

    SAExposureViewObject *exposureViewObject = [self exposureViewWithView:visibleWindow];
    if (!exposureViewObject) {
        return;
    }
    [exposureViewObject exposureConditionCheck];
}

-(NSMutableArray<SAExposureViewObject *> *)exposureViewObjects {
    if (!_exposureViewObjects) {
        _exposureViewObjects = [NSMutableArray array];
    }
    return _exposureViewObjects;
}

@end
