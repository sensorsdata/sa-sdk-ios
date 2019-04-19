//
//  UIViewController+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzler.h"
#import "AutoTrackUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
@implementation UIViewController (AutoTrack)
- (void)sa_autotrack_viewWillAppear:(BOOL)animated {
    @try {
        
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppViewScreen] == NO) {
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
            UIViewController *viewController = (UIViewController *)self;
            if (![viewController.parentViewController isKindOfClass:[UIViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
                [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
                [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
                [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
                [[SensorsAnalyticsSDK sharedInstance] autoTrackViewScreen: viewController];
            }
#else
            [[SensorsAnalyticsSDK sharedInstance] autoTrackViewScreen:self];
#endif
        }
#ifndef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW
        if ([SensorsAnalyticsSDK.sharedInstance isAutoTrackEventTypeIgnored: SensorsAnalyticsEventTypeAppClick] == NO) {
            //UITableView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW
            void (^tableViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
                [AutoTrackUtils trackAppClickWithUITableView:tableView didSelectRowAtIndexPath:indexPath];
            };
            if ([self respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:) onClass:self.class withBlock:tableViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UITableView_AutoTrack"]];
            }
#endif
            
            //UICollectionView
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW
            void (^collectionViewBlock)(id, SEL, id, id) = ^(id view, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
                [AutoTrackUtils trackAppClickWithUICollectionView:collectionView didSelectItemAtIndexPath:indexPath];
            };
            if ([self respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
                [SASwizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:) onClass:self.class withBlock:collectionViewBlock named:[NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), @"UICollectionView_AutoTrack"]];
            }
#endif
        }
#endif
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
