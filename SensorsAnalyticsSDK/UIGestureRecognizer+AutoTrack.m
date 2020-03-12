//
//  UIGestureRecognizer+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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


#import "UIGestureRecognizer+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import <objc/runtime.h>
#import "SAConstants.h"

@implementation UIGestureRecognizer (AutoTrack)

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    @try {
        // 手势处于 Ended 状态
        if (gesture.state != UIGestureRecognizerStateEnded) {
            return;
        }
        
        UIView *view = gesture.view;
        // iOS10 及以上 _UIAlertControllerInterfaceActionGroupView
        // iOS 9 及以下 _UIAlertControllerView
        if ([SAAutoTrackUtils isAlertForResponder:view]) {
            UIView *touchView = [self searchGestureTouchView:gesture];
            if (touchView) {
                view = touchView;
            }
        }

        // 是否点击弹框选项
        BOOL isAlterType = [SAAutoTrackUtils isAlertClickForView:view];
        // 暂定只采集 UILabel 和 UIImageView
        BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class] || isAlterType;
        BOOL isIgnored = ![view conformsToProtocol:@protocol(SAAutoTrackViewProperty)] || view.sensorsdata_isIgnored;
        if (!isTrackClass || isIgnored) {
            return;
        }
        NSDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:view];
        if (properties) {
            [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

// 查找弹框手势选择所在的 view
- (UIView *)searchGestureTouchView:(UIGestureRecognizer *)gesture {
    UIView *gestureView = gesture.view;
    CGPoint point = [gesture locationInView:gestureView];

    UIView *view = [gestureView.subviews lastObject];
    UIView *sequeceView = [view.subviews lastObject];
    UIView *reparatableVequeceView = [sequeceView.subviews firstObject];
    UIView *stackView = [reparatableVequeceView.subviews firstObject];

#ifndef SENSORS_ANALYTICS_DISABLE_PRIVATE_APIS
    if ([NSStringFromClass(gestureView.class) isEqualToString:@"_UIAlertControllerView"]) {
        // iOS9 上，为 UICollectionView
        stackView = [reparatableVequeceView.subviews lastObject];
    }
#endif
    
    for (UIView *subView in stackView.subviews) {
        CGRect rect = [subView convertRect:subView.bounds toView:gestureView];
        if (CGRectContainsPoint(rect, point)) { // 找到 _UIAlertControllerActionView，及 UIAlertController 响应点击的 view
            // subView 类型为 _UIInterfaceActionCustomViewRepresentationView
            // iOS9 上为 _UIAlertControllerCollectionViewCell
            return subView;
        }
    }
    return nil;
}

@end


@implementation UITapGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action {
    [self sa_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sa_addTarget:(id)target action:(SEL)action {
    [self sa_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self sa_addTarget:target action:action];
}

@end



@implementation UILongPressGestureRecognizer (AutoTrack)

- (instancetype)sa_initWithTarget:(id)target action:(SEL)action {
    [self sa_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)sa_addTarget:(id)target action:(SEL)action {
    [self sa_addTarget:self action:@selector(trackGestureRecognizerAppClick:)];
    [self sa_addTarget:target action:action];
}
@end
