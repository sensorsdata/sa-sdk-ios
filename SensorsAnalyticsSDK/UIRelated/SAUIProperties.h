//
// SAUIProperties.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAUIProperties : NSObject

+ (NSInteger)indexWithResponder:(UIResponder *)responder;

/**
 是否忽略当前元素相对路径

 @param view 当前元素
 @return 是否忽略
 */
+ (BOOL)isIgnoredItemPathWithView:(UIView *)view;

+ (NSString *)elementPathForView:(UIView *)view atViewController:(UIViewController *)viewController;

+ (nullable UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder;

+ (UIViewController *)currentViewController;

+ (NSDictionary *)propertiesWithView:(UIView *)view viewController:(UIViewController *)viewController;

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell;

+ (NSDictionary *)propertiesWithViewController:(UIViewController *)viewController;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
