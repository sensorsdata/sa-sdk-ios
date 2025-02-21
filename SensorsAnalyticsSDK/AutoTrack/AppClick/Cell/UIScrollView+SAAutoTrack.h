//
// UIScrollView+SAAutoTrack.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2019/6/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UITableViewDelegate>)delegate;

@end

@interface UICollectionView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
