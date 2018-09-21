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
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
