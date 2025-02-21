//
// SAAutoTrackUtils.m
// SensorsAnalyticsSDK
//
// Created by MC on 2019/4/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAutoTrackUtils.h"
#import "SAConstants+Private.h"
#import "SACommonUtility.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+SAAutoTrack.h"
#import "SALog.h"
#import "SAAlertController.h"
#import "SAModuleManager.h"
#import "SAValidator.h"
#import "UIView+SAInternalProperties.h"
#import "SAUIProperties.h"
#import "UIView+SensorsAnalytics.h"

/// 一个元素 $AppClick 全埋点最小时间间隔，100 毫秒
static NSTimeInterval SATrackAppClickMinTimeInterval = 0.1;

@implementation SAAutoTrackUtils

/// 在间隔时间内是否采集 $AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<SAAutoTrackViewProperty>)object {
    if (!object) {
        return NO;
    }
    
    if (![object respondsToSelector:@selector(sensorsdata_timeIntervalForLastAppClick)]) {
        return YES;
    }

    NSTimeInterval lastTime = object.sensorsdata_timeIntervalForLastAppClick;
    NSTimeInterval currentTime = [[NSProcessInfo processInfo] systemUptime];
    if (lastTime > 0 && currentTime - lastTime < SATrackAppClickMinTimeInterval) {
        return NO;
    }
    return YES;
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (Property)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<SAAutoTrackViewProperty> *)object {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<SAAutoTrackViewProperty> *)object isCodeTrack:(BOOL)isCodeTrack {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:isCodeTrack];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<SAAutoTrackViewProperty> *)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController {
    return [self propertiesWithAutoTrackObject:object viewController:viewController isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<SAAutoTrackViewProperty> *)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController isCodeTrack:(BOOL)isCodeTrack {
    if (![object respondsToSelector:@selector(sensorsdata_isIgnored)] || (!isCodeTrack && object.sensorsdata_isIgnored)) {
        return nil;
    }

    viewController = viewController ? : object.sensorsdata_viewController;
    if (!isCodeTrack && viewController.sensorsdata_isIgnored) {
        return nil;
    }
    NSDictionary *properties = [SAUIProperties propertiesWithView:object viewController:viewController];
    return [NSMutableDictionary dictionaryWithDictionary:properties];
}

@end

#pragma mark -
@implementation SAAutoTrackUtils (IndexPath)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (![object respondsToSelector:@selector(sensorsdata_isIgnored)] || object.sensorsdata_isIgnored) {
        return nil;
    }
    NSDictionary *properties = [SAUIProperties propertiesWithScrollView:object andIndexPath:indexPath];
    return [NSMutableDictionary dictionaryWithDictionary:properties];
}

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *properties = nil;
    @try {
        if ([scrollView isKindOfClass:UITableView.class]) {
            UITableView *tableView = (UITableView *)scrollView;
            
            if ([tableView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [tableView.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath];
            }
        } else if ([scrollView isKindOfClass:UICollectionView.class]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            if ([collectionView.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [collectionView.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath];
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
    NSAssert(!properties || [properties isKindOfClass:[NSDictionary class]], @"You must return a dictionary object ❌");
    return properties;
}
@end
