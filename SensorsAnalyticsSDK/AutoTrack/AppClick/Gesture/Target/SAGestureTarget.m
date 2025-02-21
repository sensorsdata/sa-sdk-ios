//
// SAGestureTarget.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAGestureTarget.h"
#import "SAGestureViewProcessorFactory.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "UIView+SAAutoTrack.h"
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
