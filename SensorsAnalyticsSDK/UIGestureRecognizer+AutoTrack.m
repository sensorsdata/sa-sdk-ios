//
//  UIGestureRecognizer+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2018 Sensors Data Inc. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIGestureRecognizer+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "UIView+AutoTrack.h"
#import "AutoTrackUtils.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"
#import <objc/runtime.h>
#import "SAConstants.h"

@implementation UIGestureRecognizer (AutoTrack)

- (void)trackGestureRecognizerAppClick:(id)target {
    
    //暂定只采集 UILabel 和 UIImageView
    if (![self.view isKindOfClass:UILabel.class] && ![self.view isKindOfClass:UIImageView.class]) {
        return;
    }
    
    @try {
        if (target == nil) {
            return;
        }
        UIGestureRecognizer *gesture = target;
        if (gesture == nil) {
            return;
        }
        
        if (gesture.state != UIGestureRecognizerStateEnded) {
            return;
        }
        
        UIView *view = gesture.view;
        if (view == nil) {
            return;
        }
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }
        
        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }
        
        if ([view isKindOfClass:[UILabel class]]) {//UILabel
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UILabel class]]) {
                return;
            }
        } else if ([view isKindOfClass:[UIImageView class]]) {//UIImageView
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIImageView class]]) {
                return;
            }
        }
        
        UIViewController *viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        if (viewController != nil) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewControllerIgnored:viewController]) {
                return;
            }
            
            //获取 Controller 名称($screen_name)
            NSString *screenName = NSStringFromClass([viewController class]);
            [properties setValue:screenName forKey:SA_EVENT_PROPERTY_SCREEN_NAME];
            
            NSString *controllerTitle = [AutoTrackUtils titleFromViewController:viewController];
            if (controllerTitle) {
                [properties setValue:controllerTitle forKey:SA_EVENT_PROPERTY_TITLE];
            }
        }
        
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:SA_EVENT_PROPERTY_ELEMENT_ID];
        }
        
        if ([view isKindOfClass:[UILabel class]]) {
            [properties setValue:@"UILabel" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];
            UILabel *label = (UILabel*)view;
            NSString *sa_elementContent = label.sa_elementContent;
            if (sa_elementContent && sa_elementContent.length > 0) {
                [properties setValue:sa_elementContent forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
            }
            [AutoTrackUtils sa_addViewPathProperties:properties withObject:view withViewController:viewController];
        } else if ([view isKindOfClass:[UIImageView class]]) {
            [properties setValue:@"UIImageView" forKey:SA_EVENT_PROPERTY_ELEMENT_TYPE];
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
            UIImageView *imageView = (UIImageView *)view;
            [AutoTrackUtils sa_addViewPathProperties:properties withObject:view withViewController:viewController];

            NSString *imageName = imageView.image.sensorsAnalyticsImageName;
            if (imageName.length > 0) {
                [properties setValue:[NSString stringWithFormat:@"$%@", imageName] forKey:SA_EVENT_PROPERTY_ELEMENT_CONTENT];
            }
#endif
        }else {
            return;
        }
        
        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }
        
        [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
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
