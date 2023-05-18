//
// SAExposureDelegateProxy.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/15.
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

#import "SAExposureDelegateProxy.h"
#import <UIKit/UIKit.h>
#import "SAExposureViewObject.h"
#import "SAExposureManager.h"
#import "UIScrollView+SADelegateHashTable.h"
#import <objc/runtime.h>
#import "SALog.h"

@implementation SAExposureDelegateProxy

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.sensorsdata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.sensorsdata_exposure_delegateHashTable addObject:self];

    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:cell];
    exposureViewObject.state = (exposureViewObject.state == SAExposureViewStateExposing ? SAExposureViewStateExposing : SAExposureViewStateVisible);
    exposureViewObject.scrollView = tableView;
    exposureViewObject.indexPath = indexPath;
    [exposureViewObject exposureConditionCheck];

    //invoke original
    SEL methodSelector = @selector(tableView:willDisplayCell:forRowAtIndexPath:);
    if (class_getInstanceMethod(tableView.delegate.class, methodSelector)) {
        [SAExposureDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, cell, indexPath];
    }

    [tableView.sensorsdata_exposure_delegateHashTable removeAllObjects];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.sensorsdata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.sensorsdata_exposure_delegateHashTable addObject:self];

    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:cell];
    if (![tableView.indexPathsForVisibleRows containsObject:indexPath]) {
        exposureViewObject.state = SAExposureViewStateInvisible;
    }

    //invoke original
    SEL methodSelector = @selector(tableView:didEndDisplayingCell:forRowAtIndexPath:);
    if (class_getInstanceMethod(tableView.delegate.class, methodSelector)) {
        [SAExposureDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, cell, indexPath];
    }

    [tableView.sensorsdata_exposure_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.sensorsdata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.sensorsdata_exposure_delegateHashTable addObject:self];
    
    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:cell];
    exposureViewObject.state = (exposureViewObject.state == SAExposureViewStateExposing ? SAExposureViewStateExposing : SAExposureViewStateVisible);
    exposureViewObject.scrollView = collectionView;
    exposureViewObject.indexPath = indexPath;
    [exposureViewObject exposureConditionCheck];

    //invoke original
    SEL methodSelector = @selector(collectionView:willDisplayCell:forItemAtIndexPath:);
    if (class_getInstanceMethod(collectionView.delegate.class, methodSelector)) {
        [SAExposureDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, cell, indexPath];
    }

    [collectionView.sensorsdata_exposure_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.sensorsdata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.sensorsdata_exposure_delegateHashTable addObject:self];

    SAExposureViewObject *exposureViewObject = [[SAExposureManager defaultManager] exposureViewWithView:cell];
    if (![collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
        exposureViewObject.state = SAExposureViewStateInvisible;
    }

    //invoke original
    SEL methodSelector = @selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:);
    if (class_getInstanceMethod(collectionView.delegate.class, methodSelector)) {
        [SAExposureDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, cell, indexPath];
    }

    [collectionView.sensorsdata_exposure_delegateHashTable removeAllObjects];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"tableView:willDisplayCell:forRowAtIndexPath:", @"tableView:didEndDisplayingCell:forRowAtIndexPath:", @"collectionView:willDisplayCell:forItemAtIndexPath:", @"collectionView:didEndDisplayingCell:forItemAtIndexPath:"]];
}

@end
