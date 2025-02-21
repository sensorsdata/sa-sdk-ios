//
// SAExposureView.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAExposureData.h"
#import "SAExposureTimer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SAExposureViewState) {
    SAExposureViewStateVisible,
    SAExposureViewStateInvisible,
    SAExposureViewStateBackgroundInvisible,
    SAExposureViewStateExposing,
};

typedef NS_ENUM(NSUInteger, SAExposureViewType) {
    SAExposureViewTypeNormal,
    SAExposureViewTypeCell,
};

@interface SAExposureViewObject : NSObject

@property (nonatomic, weak) UIView *view;
@property (nonatomic, assign) SAExposureViewState state;
@property (nonatomic, assign) SAExposureViewType type;
@property (nonatomic, strong) SAExposureData *exposureData;
@property (nonatomic, weak, readonly) UIViewController *viewController;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) NSTimeInterval lastExposure;
@property (nonatomic, assign) CGFloat lastAreaRate;
@property (nonatomic, strong) SAExposureTimer *timer;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithView:(UIView *)view exposureData:(SAExposureData *)exposureData;

- (void)addExposureViewObserver;
- (void)clear;
- (void)exposureConditionCheck;
- (void)findNearbyScrollView;

@end

NS_ASSUME_NONNULL_END
