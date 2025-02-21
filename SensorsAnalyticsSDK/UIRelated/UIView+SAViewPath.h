//
// UIView+SAViewPath.h
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2024/3/5.
// Copyright © 2015-2024 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAUIViewPathProperties.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SAViewPath) <SAUIViewPathProperties>

@end

@interface UISegmentedControl (SAViewPath) <SAUIViewPathProperties>

@end

@interface UITableViewHeaderFooterView (SAViewPath) <SAUIViewPathProperties>

@end

@interface UITableViewCell (SAViewPath) <SAUIViewPathProperties>

@end

@interface UICollectionViewCell (SAViewPath) <SAUIViewPathProperties>

@end

@interface UIAlertController (SAViewPath) <SAUIViewPathProperties>

@end

NS_ASSUME_NONNULL_END
