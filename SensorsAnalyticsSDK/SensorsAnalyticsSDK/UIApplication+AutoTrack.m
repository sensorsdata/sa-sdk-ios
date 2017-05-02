//
//  UIApplication+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 17/3/22.
//  Copyright (c) 2017年 SensorsData. All rights reserved.
//

#import "UIApplication+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"

@implementation UIApplication (AutoTrack)

- (BOOL)sa_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    /*
     注意调用顺序，否则tabBar的selectedItem还是上次选择的
     */
    BOOL ret = [self sa_sendAction:action to:to from:from forEvent:event];
    [self sa_track:action to:to from:from forEvent:event];
    return ret;
}

- (void)sa_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    //关闭 AutoTrack
    if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
        return;
    }
    
    //忽略 $AppClick 事件
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
        return;
    }
    
    // ViewType 被忽略
    if ([from isKindOfClass:[NSClassFromString(@"UITabBarButton") class]]) {
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITabBar class]]) {
            return;
        }
    } else if ([from isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIBarButtonItem class]]) {
            return;
        }
    } else if ([to isKindOfClass:[UISearchBar class]]) {
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UISearchBar class]]) {
            return;
        }
    } else {
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[from class]]) {
            return;
        }
    }
    
    if (event.type==UIEventTypeTouches) {//0
        if (![from isKindOfClass:[UIView class]]) {
            return;
        }
        
        UIView* view = (UIView *)from;
        if (!view) {
            return;
        }
        
        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }
        
        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }
        
        //获取 Controller 的 title($title)
//        if ([to isKindOfClass:[UIViewController class]]) {
//            UIViewController *viewController = (UIViewController*)to;
            UIViewController *viewController = [view viewController];

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
            }
//        }
        
        //UISwitch
        if ([from isKindOfClass:[UISwitch class]]) {
            [properties setValue:@"UISwitch" forKey:@"$element_type"];
            [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
            return;
        }
        
        //UISearchBar
//        if ([to isKindOfClass:[UISearchBar class]] && [from isKindOfClass:[[NSClassFromString(@"UISearchBarTextField") class] class]]) {
//            UISearchBar *searchBar = (UISearchBar *)to;
//            if (searchBar != nil) {
//                [properties setValue:@"UISearchBar" forKey:@"$element_type"];
//                NSString *searchText = searchBar.text;
//                if (searchText == nil || [searchText length] == 0) {
//                    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
//                    return;
//                }
//            }
//        }

        //UISegmentedControl
        if ([from isKindOfClass:[UISegmentedControl class]]) {
            UISegmentedControl *segmented = (UISegmentedControl *)from;
            [properties setValue:@"UISegmentedControl" forKey:@"$element_type"];
            [properties setValue:[NSString stringWithFormat: @"%ld", [segmented selectedSegmentIndex]] forKey:@"$element_position"];
            [properties setValue:[segmented titleForSegmentAtIndex:[segmented selectedSegmentIndex]] forKey:@"$element_content"];
            [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
            return;
            
        }
        
        //只统计触摸结束时
        if ([[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
            if ([from isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
                UIButton *button = (UIButton *)from;
                [properties setValue:@"UIBarButtonItem" forKey:@"$element_type"];
                if (button != NULL) {
                    [properties setValue:[button currentTitle] forKey:@"$element_content"];
                }
            } else if ([from isKindOfClass:[UIButton class]]) {//UIButton
                UIButton *button = (UIButton *)from;
                [properties setValue:@"UIButton" forKey:@"$element_type"];
                if (button != NULL) {
                    [properties setValue:[button currentTitle] forKey:@"$element_content"];
                }
            } else if ([from isKindOfClass:[NSClassFromString(@"UITabBarButton") class]]) {//UITabBarButton
                if ([to isKindOfClass:[UITabBar class]]) {//UITabBar
                    UITabBar *tabBar = (UITabBar *)to;
                    if (tabBar != nil) {
                        UITabBarItem *item = [tabBar selectedItem];
                        [properties setValue:@"UITabbar" forKey:@"$element_type"];
                        [properties setValue:item.title forKey:@"$element_content"];
                    }
                }
            } else if ([from isKindOfClass:[UISlider class]]) {//UISlider
                UISlider *slide = (UISlider *)from;
                if (slide != nil) {
                    [properties setValue:@"UISlider" forKey:@"$element_type"];
                    [properties setValue:[NSString stringWithFormat:@"%f",slide.value] forKey:@"$element_content"];
                }
            }
            [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
        }
    }
}

@end
