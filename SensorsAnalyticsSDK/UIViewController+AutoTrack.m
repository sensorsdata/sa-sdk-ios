//
//  UIViewController.m
//  HookTest
//
//  Created by 王灼洲 on 2017/10/18.
//  Copyright © 2017年 wanda. All rights reserved.
//

#import "UIViewController+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"

@implementation UIViewController (AutoTrack)
- (void)sa_autotrack_viewWillAppear:(BOOL)animated {
    @try {
        UIViewController *viewController = (UIViewController *)self;
        [[SensorsAnalyticsSDK sharedInstance] trackViewScreen: viewController];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [self sa_autotrack_viewWillAppear:animated];
}
@end
