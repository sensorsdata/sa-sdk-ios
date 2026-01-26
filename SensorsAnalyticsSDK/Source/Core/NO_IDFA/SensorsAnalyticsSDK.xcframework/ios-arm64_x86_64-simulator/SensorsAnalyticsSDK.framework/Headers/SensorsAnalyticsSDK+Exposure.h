//
// SensorsAnalyticsSDK+Exposure.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SensorsAnalyticsSDK.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK (Exposure)

/// use this method to add exposure to certain view
/// - Parameters:
///   - view: view to expose
///   - data: exposure data, such as event name, properties, etc.
- (void)addExposureView:(UIView *)view withData:(SAExposureData *)data NS_EXTENSION_UNAVAILABLE("Exposure not supported for iOS extensions.");

/// use this method to add exposure to UITableViewCell or UICollectionViewCell
/// - Parameters:
///   - view: view to expose
///   - scrollView UITableView or UICollectionView
///   - data: exposure data, such as event name, properties, etc.
- (void)addExposureView:(UIView *)view inScrollView:(UIScrollView *)scrollView withData:(SAExposureData *)data NS_EXTENSION_UNAVAILABLE("Exposure not supported for iOS extensions.");

/// remove exposure for certain view
/// - Parameters:
///   - view: view that need to remove exposure
///   - identifier: exposure identifier to identify certain view, if no identifier specified when addExposureView
- (void)removeExposureView:(nullable UIView *)view withExposureIdentifier:(nullable NSString *)identifier NS_EXTENSION_UNAVAILABLE("Exposure not supported for iOS extensions.");

/// update properties for certain view that need to expose
/// - Parameters:
///   - view: view to expose
///   - properties: properties to update
- (void)updateExposure:(UIView *)view withProperties:(NSDictionary *)properties NS_EXTENSION_UNAVAILABLE("Exposure not supported for iOS extensions.");

@end

NS_ASSUME_NONNULL_END
