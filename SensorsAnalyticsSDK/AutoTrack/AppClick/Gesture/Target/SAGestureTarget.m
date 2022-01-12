//
// SAGestureTarget.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
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

#import "SAGestureTarget.h"
#import "SAGestureViewProcessorFactory.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "UIView+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SAAutoTrackManager.h"

@implementation SAGestureTarget

+ (SAGestureTarget * _Nullable)targetWithGesture:(UIGestureRecognizer *)gesture {
    NSString *gestureType = NSStringFromClass(gesture.class);
    if ([gesture isMemberOfClass:UITapGestureRecognizer.class] ||
        [gesture isMemberOfClass:UILongPressGestureRecognizer.class] ||
        [gestureType isEqualToString:@"_UIContextMenuSelectionGestureRecognizer"]) {
        return [[SAGestureTarget alloc] init];
    }
    return nil;
}

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded &&
        gesture.state != UIGestureRecognizerStateCancelled) {
        return;
    }
    SAGeneralGestureViewProcessor *processor = [SAGestureViewProcessorFactory processorWithGesture:gesture];
    if (!processor.isTrackable) {
        return;
    }

    [SAAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithGestureView:processor.trackableView];
}

@end
