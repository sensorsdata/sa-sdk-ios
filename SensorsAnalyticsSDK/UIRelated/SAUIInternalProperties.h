//
// SAUIViewInternalProperties.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/30.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SAUIViewControllerInternalProperties <NSObject>

@property (nonatomic, copy, readonly) NSString *sensorsdata_screenName;
@property (nonatomic, copy, readonly) NSString *sensorsdata_title;

@end

@protocol SAUIViewInternalProperties <NSObject>

@property (nonatomic, weak, readonly) UIViewController<SAUIViewControllerInternalProperties> *sensorsdata_viewController;
- (UIScrollView *)sensorsdata_nearbyScrollView;

@end
