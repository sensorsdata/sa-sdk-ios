//
//  UIViewController.m
//  HookTest
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//
#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzler.h"
#import "SensorsAnalyticsSDK+Private.h"
@implementation UIViewController (AutoTrack)
- (void)sa_autotrack_viewWillAppear:(BOOL)animated {
    @try {
        
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppViewScreen] == NO) {
            UIViewController *viewController = (UIViewController *)self;
            if (![viewController.parentViewController isKindOfClass:[UIViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
                [viewController.parentViewController isKindOfClass:[UINavigationController class]] ) {
                [[SensorsAnalyticsSDK sharedInstance] trackViewScreen: viewController];
            }
        }
        if ([SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
            //UITableView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW
            void (^tableViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
                [SensorsAnalyticsSDK.sharedInstance tableView:tableView didSelectRowAtIndexPath:indexPath];
            };
            if ([self respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:) onClass:self.class withBlock:tableViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UITableView_AutoTrack"]];
            }
#endif
            
            //UICollectionView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW
            void (^collectionViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
                [SensorsAnalyticsSDK.sharedInstance collectionView:collectionView didSelectItemAtIndexPath:indexPath];
            };
            if ([self respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:) onClass:self.class withBlock:collectionViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UICollectionView_AutoTrack"]];
            }
#endif
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
