//
// SAScrollViewDelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
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

#import "SAScrollViewDelegateProxy.h"
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "UIScrollView+SAAutoTrack.h"
#import "SAAutoTrackManager.h"
#import <objc/message.h>
#import "UIScrollView+SADelegateHashTable.h"

@implementation SAScrollViewDelegateProxy

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.sensorsdata_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.sensorsdata_delegateHashTable addObject:self];
    
    SEL methodSelector = @selector(tableView:didSelectRowAtIndexPath:);
    [SAScrollViewDelegateProxy trackEventWithTarget:self scrollView:tableView atIndexPath:indexPath];
    [SAScrollViewDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, indexPath];
    
    [tableView.sensorsdata_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.sensorsdata_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.sensorsdata_delegateHashTable addObject:self];
    
    SEL methodSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    [SAScrollViewDelegateProxy trackEventWithTarget:self scrollView:collectionView atIndexPath:indexPath];
    [SAScrollViewDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, indexPath];
    
    [collectionView.sensorsdata_delegateHashTable removeAllObjects];
}

+ (void)trackEventWithTarget:(NSObject *)target scrollView:(UIScrollView *)scrollView atIndexPath:(NSIndexPath *)indexPath {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != scrollView.delegate) {
        return;
    }

    [SAAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithScrollView:scrollView atIndexPath:indexPath];
}

@end
