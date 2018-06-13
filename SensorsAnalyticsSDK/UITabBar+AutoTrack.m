//
//  TabBar.m
//  daHePai
//
//  Created by 王灼洲 on 2017/6/21.
//  Copyright © 2017年 DHP. All rights reserved.
//

#import "UITabBar+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "UIView+AutoTrack.h"
@implementation UITabBar (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABBAR

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSError *error = NULL;
            [[self class] sa_swizzleMethod:@selector(setDelegate:)
                                withMethod:@selector(sa_uiTabBarSetDelegate:)
                                     error:&error];
            if (error) {
                SAError(@"Failed to swizzle setDelegate: on UITabBar. Details: %@", error);
                error = NULL;
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
    });
}

void sa_uiTabBarDidSelectRowAtIndexPath(id self, SEL _cmd, id tabBar, UITabBarItem* item) {
    SEL selector = NSSelectorFromString(@"sa_uiTabBarDidSelectRowAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tabBar, item);
    
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
        
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITabBar class]]) {
            return;
        }
        
        if (!tabBar) {
            return;
        }
        
        UIView *view = (UIView *)tabBar;
        if (!view) {
            return;
        }
        
        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        [properties setValue:@"UITabBar" forKey:@"$element_type"];
        
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
                                        NSString *currentTitle = button.sa_elementContent;
                                        if (currentTitle != nil && currentTitle.length > 0) {
                                            elementContent = [elementContent stringByAppendingString:currentTitle];
                                            elementContent = [elementContent stringByAppendingString:@"-"];
                                        }
                                       
                                    } else if ([subView isKindOfClass:[UILabel class]]) {
                                        UILabel *label = (UILabel *)subView;
                                        NSString *currentTitle = label.sa_elementContent;
                                        if (currentTitle != nil && currentTitle.length > 0) {
                                            elementContent = [elementContent stringByAppendingString:currentTitle];
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
        
        if (item) {
            [properties setValue:item.title forKey:@"$element_content"];
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

- (void)sa_uiTabBarSetDelegate:(id<UITabBarDelegate>)delegate {
    [self sa_uiTabBarSetDelegate:delegate];
    
    @try {
        Class class = [delegate class];
        //        static dispatch_once_t onceToken;
        //        dispatch_once(&onceToken, ^{
        if (class_addMethod(class, NSSelectorFromString(@"sa_uiTabBarDidSelectRowAtIndexPath"), (IMP)sa_uiTabBarDidSelectRowAtIndexPath, "v@:@@")) {
            Method dis_originMethod = class_getInstanceMethod(class, NSSelectorFromString(@"sa_uiTabBarDidSelectRowAtIndexPath"));
            Method dis_swizzledMethod = class_getInstanceMethod(class, @selector(tabBar:didSelectItem:));
            method_exchangeImplementations(dis_originMethod, dis_swizzledMethod);
        }
        //        });
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

#endif

@end
