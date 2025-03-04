//
// SAAutoTrackUtils.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2019/4/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackUtils : NSObject

/// 在间隔时间内是否采集 $AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<SAAutoTrackViewProperty>)object;

@end

#pragma mark -
@interface SAAutoTrackUtils (Property)

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param isCodeTrack 是否代码埋点采集
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object isCodeTrack:(BOOL)isCodeTrack;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param viewController 控件所在的 ViewController，当为 nil 时，自动采集当前界面上的 ViewController
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController;

@end

#pragma mark -
@interface SAAutoTrackUtils (IndexPath)

+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
