//
//  UIAlertView.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/13.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "UIAlertView+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIAlertView (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIALERTVIEW

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        @try {
//            NSError *error = NULL;
//            [[self class] sa_swizzleMethod:@selector(setDelegate:)
//                                withMethod:@selector(sa_alertViewSetDelegate:)
//                                     error:&error];
//            if (error) {
//                SAError(@"Failed to swizzle setDelegate: on UIAlertView. Details: %@", error);
//                error = NULL;
//            }
//        } @catch (NSException *exception) {
//            SAError(@"%@ error: %@", self, exception);
//        }
//    });
//}

void sa_alertViewClickedButtonAtIndex(id self, SEL _cmd, id alertView, NSInteger buttonIndex) {
    SEL selector = NSSelectorFromString(@"sa_alertViewClickedButtonAtIndex");
    ((void(*)(id, SEL, id, NSInteger))objc_msgSend)(self, selector, alertView, buttonIndex);
    //插入埋点
    
    @try {
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }
        
        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }
        
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIAlertView class]]) {
            return;
        }
        
        if (!alertView) {
            return;
        }

        UIView *view = (UIView *)alertView;
        if (!view) {
            return;
        }
        
        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        [properties setValue:@"UIAlertView" forKey:@"$element_type"];
        
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }
        
        UIViewController *viewController = [view viewController];
        
        if (viewController == nil ||
            [@"UINavigationController" isEqualToString:NSStringFromClass([viewController class])]) {
            viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        }
        
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
            } else {
                @try {
                    UIView *titleView = viewController.navigationItem.titleView;
                    if (titleView != nil) {
                        if (titleView.subviews.count > 0) {
                            NSString *elementContent = [[NSString alloc] init];
                            for (UIView *subView in [titleView subviews]) {
                                if (subView) {
                                    if (subView.sensorsAnalyticsIgnoreView) {
                                        continue;
                                    }
                                    if ([subView isKindOfClass:[UIButton class]]) {
                                        UIButton *button = (UIButton *)subView;
                                        if ([button currentTitle] != nil && ![@"" isEqualToString:[button currentTitle]]) {
                                            elementContent = [elementContent stringByAppendingString:[button currentTitle]];
                                            elementContent = [elementContent stringByAppendingString:@"-"];
                                        }
                                    } else if ([subView isKindOfClass:[UILabel class]]) {
                                        UILabel *label = (UILabel *)subView;
                                        if (label.text != nil && ![@"" isEqualToString:label.text]) {
                                            elementContent = [elementContent stringByAppendingString:label.text];
                                            elementContent = [elementContent stringByAppendingString:@"-"];
                                        }
                                    }
                                }
                            }
                            if (elementContent != nil && [elementContent length] > 0) {
                                elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                                [properties setValue:elementContent forKey:@"$title"];
                            }
                        }
                    }
                } @catch (NSException *exception) {
                    SAError(@"%@: %@", self, exception);
                }
            }
        }
        
        [properties setValue:[alertView buttonTitleAtIndex:buttonIndex] forKey:@"$element_content"];
//        [properties setValue:[alertView title] forKey:@"alertView_title"];
//        [properties setValue:[alertView message] forKey:@"alertView_message"];
        
        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }
        
        @try {
//            if (view.sensorsAnalyticsDelegate) {
//                if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)]) {
//                    if ([view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_alertView:clickedButtonAtIndex:)]) {
//                        [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_alertView:alertView clickedButtonAtIndex:buttonIndex]];
//                    }
//                }
//            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
        
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)sa_alertViewSetDelegate:(id)delegate {
    [self sa_alertViewSetDelegate:delegate];
    
    @try {
        Class class = [delegate class];
        
        if (class_addMethod(class, NSSelectorFromString(@"sa_alertViewClickedButtonAtIndex"), (IMP)sa_alertViewClickedButtonAtIndex, "v@:@@")) {
            Method dis_originMethod = class_getInstanceMethod(class, NSSelectorFromString(@"sa_alertViewClickedButtonAtIndex"));
            Method dis_swizzledMethod = class_getInstanceMethod(class, @selector(alertView:clickedButtonAtIndex:));
            method_exchangeImplementations(dis_originMethod, dis_swizzledMethod);
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

#endif

@end
