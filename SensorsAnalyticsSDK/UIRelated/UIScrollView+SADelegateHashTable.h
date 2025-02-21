//
// UIScrollView+SADelegateHashTable.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/9/3.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (SADelegateHashTable)

@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_delegateHashTable;

@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_exposure_delegateHashTable;

@end

@interface UICollectionView (SADelegateHashTable)

@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_delegateHashTable;

@property (nonatomic, strong, nullable) NSHashTable *sensorsdata_exposure_delegateHashTable;

@end

NS_ASSUME_NONNULL_END
