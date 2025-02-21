//
// UIScrollView+SAAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2019/6/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+SAAutoTrack.h"
#import "SAScrollViewDelegateProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "SAConstants+Private.h"
#import "SAAutoTrackManager.h"

@implementation UITableView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UITableViewDelegate>)delegate {
    //resolve optional selectors
    [SAScrollViewDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self sensorsdata_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }
    
    // 判断是否忽略 $AppClick 事件采集
    if ([SAAutoTrackManager.defaultManager isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [SAScrollViewDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"tableView:didSelectRowAtIndexPath:"]]];
}

@end


@implementation UICollectionView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UICollectionViewDelegate>)delegate {
    //resolve optional selectors
    [SAScrollViewDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self sensorsdata_setDelegate:delegate];
    
    if (!delegate || !self.delegate) {
        return;
    }
    
    // 判断是否忽略 $AppClick 事件采集
    if ([SAAutoTrackManager.defaultManager isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [SAScrollViewDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"collectionView:didSelectItemAtIndexPath:"]]];
}

@end
