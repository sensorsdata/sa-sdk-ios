//
// UIScrollView+SAAutoTrack.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2019/6/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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

static const void *kSATableViewIndexPath = &kSATableViewIndexPath;
static const void *kSACollectionViewIndexPath = &kSACollectionViewIndexPath;

@implementation UITableView (AutoTrack)

- (void)setSensorsdata_indexPath:(NSIndexPath *)indexPath {
    objc_setAssociatedObject(self, kSATableViewIndexPath, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)sensorsdata_indexPath {
    return  objc_getAssociatedObject(self, kSATableViewIndexPath);
}

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

- (void)setSensorsdata_indexPath:(NSIndexPath *)indexPath {
    objc_setAssociatedObject(self, kSACollectionViewIndexPath, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)sensorsdata_indexPath {
    return  objc_getAssociatedObject(self, kSACollectionViewIndexPath);
}

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
