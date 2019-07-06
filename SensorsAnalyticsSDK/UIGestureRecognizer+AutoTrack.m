//
//  UIGestureRecognizer+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
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
        UIView *view = gesture.view;
        // 暂定只采集 UILabel 和 UIImageView
        BOOL isTrackClass = [view isKindOfClass:UILabel.class] || [view isKindOfClass:UIImageView.class];
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
