//
// UIScrollView+ExposureListener.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/15.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+ExposureListener.h"
#import "SAExposureDelegateProxy.h"

@implementation UITableView (SAExposureListener)

- (void)sensorsdata_exposure_setDelegate:(id <UITableViewDelegate>)delegate {
    //resolve optional selectors
    [SAExposureDelegateProxy resolveOptionalSelectorsForDelegate:delegate];

    [self sensorsdata_exposure_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }

    // 使用委托类去 hook 点击事件方法
    [SAExposureDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"tableView:willDisplayCell:forRowAtIndexPath:", @"tableView:didEndDisplayingCell:forRowAtIndexPath:"]]];
}

@end


@implementation UICollectionView (SAExposureListener)

- (void)sensorsdata_exposure_setDelegate:(id <UICollectionViewDelegate>)delegate {
    //resolve optional selectors
    [SAExposureDelegateProxy resolveOptionalSelectorsForDelegate:delegate];

    [self sensorsdata_exposure_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }

    // 使用委托类去 hook 点击事件方法
    [SAExposureDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"collectionView:willDisplayCell:forItemAtIndexPath:", @"collectionView:didEndDisplayingCell:forItemAtIndexPath:"]]];
}

@end
