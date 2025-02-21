//
// UIView+SensorsAnalytics.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SAUIViewAutoTrackDelegate <NSObject>

//UITableView
@optional
- (NSDictionary *)sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
- (NSDictionary *)sensorsAnalytics_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UIView (SensorsAnalytics)

/// viewID
@property (nonatomic, copy) NSString *sensorsAnalyticsViewID;

/// AutoTrack 时，是否忽略该 View
@property (nonatomic, assign) BOOL sensorsAnalyticsIgnoreView;

/// AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic, assign) BOOL sensorsAnalyticsAutoTrackAfterSendAction;

/// AutoTrack 时，View 的扩展属性
@property (nonatomic, strong) NSDictionary *sensorsAnalyticsViewProperties;

@property (nonatomic, weak, nullable) id<SAUIViewAutoTrackDelegate> sensorsAnalyticsDelegate;

@end

@interface UIImage (SensorsAnalytics)

@property (nonatomic, copy) NSString* sensorsAnalyticsImageName;

@end

NS_ASSUME_NONNULL_END
