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
#import <objc/runtime.h>

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
            [properties setValue:screenName forKey:@"$screen_name"];
            
            NSString *controllerTitle = viewController.navigationItem.title;
            if (controllerTitle != nil) {
                [properties setValue:viewController.navigationItem.title forKey:@"$title"];
            }
            
            //再获取 controller.navigationItem.titleView, 并且优先级比较高
            NSString *elementContent = [[SensorsAnalyticsSDK sharedInstance] getUIViewControllerTitle:viewController];
            if (elementContent != nil && [elementContent length] > 0) {
                elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                [properties setValue:elementContent forKey:@"$title"];
            }
        }
        
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }
        
        if ([view isKindOfClass:[UILabel class]]) {
            [properties setValue:@"UILabel" forKey:@"$element_type"];
            UILabel *label = (UILabel*)view;
            NSString *sa_elementContent = label.sa_elementContent;
            if (sa_elementContent && sa_elementContent.length > 0) {
                [properties setValue:sa_elementContent forKey:@"$element_content"];
            }
            [AutoTrackUtils sa_addViewPathProperties:properties withObject:view withViewController:viewController];
        } else if ([view isKindOfClass:[UIImageView class]]) {
            [properties setValue:@"UIImageView" forKey:@"$element_type"];
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
            UIImageView *imageView = (UIImageView *)view;
            [AutoTrackUtils sa_addViewPathProperties:properties withObject:view withViewController:viewController];
            if (imageView) {
                if (imageView.image) {
                    NSString *imageName = imageView.image.sensorsAnalyticsImageName;
                    if (imageName != nil) {
                        [properties setValue:[NSString stringWithFormat:@"$%@", imageName] forKey:@"$element_content"];
                    }
                }
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
        
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
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
