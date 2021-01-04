//
//  UIScrollView+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超🍎 on 2019/6/19.
//  Copyright © 2019 SensorsData. All rights reserved.
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

#import "UIScrollView+AutoTrack.h"
#import "SADelegateProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"

@implementation UITableView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UITableViewDelegate>)delegate {
    [self sensorsdata_setDelegate:delegate];

    if (self.delegate == nil) {
        return;
    }
    // 判断是否忽略 $AppClick 事件采集
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [SADelegateProxy proxyWithDelegate:self.delegate];
}

@end


@implementation UICollectionView (AutoTrack)

- (void)sensorsdata_setDelegate:(id <UICollectionViewDelegate>)delegate {
    [self sensorsdata_setDelegate:delegate];

    if (self.delegate == nil) {
        return;
    }
    // 判断是否忽略 $AppClick 事件采集
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [SADelegateProxy proxyWithDelegate:self.delegate];
}

@end
