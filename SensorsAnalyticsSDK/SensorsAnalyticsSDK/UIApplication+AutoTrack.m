//
//  UIApplication+AutoTrack.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 17/3/22.
//  Copyright (c) 2017年 SensorsData. All rights reserved.
//

#import "UIApplication+AutoTrack.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"
#import "AutoTrackUtils.h"
#import "UIView+SAHelpers.h"

@implementation UIApplication (AutoTrack)

- (BOOL)sa_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {

    /*
     默认先执行 AutoTrack
     如果先执行原点击处理逻辑，可能已经发生页面 push 或者 pop，导致获取当前 ViewController 不正确
     可以通过 UIView 扩展属性 sensorsAnalyticsAutoTrackAfterSendAction，来配置 AutoTrack 是发生在原点击处理函数之前还是之后
     */

    BOOL ret = YES;
    BOOL sensorsAnalyticsAutoTrackAfterSendAction = NO;

    @try {
        if (from) {
            if ([from isKindOfClass:[UIView class]]) {
                UIView* view = (UIView *)from;
                if (view) {
                    if (view.sensorsAnalyticsAutoTrackAfterSendAction) {
                        sensorsAnalyticsAutoTrackAfterSendAction = YES;
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
        sensorsAnalyticsAutoTrackAfterSendAction = NO;
    }

    if (sensorsAnalyticsAutoTrackAfterSendAction) {
        ret = [self sa_sendAction:action to:to from:from forEvent:event];
    }

    @try {
        /*
         caojiangPreVerify:forEvent: & caojiangEventAction:forEvent: 是我们可视化埋点中的点击事件
         这个地方如果不过滤掉，会导致 swizzle 多次，从而会触发多次 $AppClick 事件
         caojiang 是我们 CTO 名字，我们相信这个前缀应该是唯一的
         如果这个前缀还会重复，请您告诉我，我把我们架构师的名字也加上
         */
        if (![@"caojiangPreVerify:forEvent:" isEqualToString:NSStringFromSelector(action)] &&
            ![@"caojiangEventAction:forEvent:" isEqualToString:NSStringFromSelector(action)]) {
            [self sa_track:action to:to from:from forEvent:event];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }

    if (!sensorsAnalyticsAutoTrackAfterSendAction) {
        ret = [self sa_sendAction:action to:to from:from forEvent:event];
    }

    return ret;
}

- (void)sa_track:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    @try {
        //关闭 AutoTrack
        if (![[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
            return;
        }
        
        //忽略 $AppClick 事件
        if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEventTypeIgnored:SensorsAnalyticsEventTypeAppClick]) {
            return;
        }
        
        // ViewType 被忽略
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
        if ([from isKindOfClass:[NSClassFromString(@"UITabBarButton") class]]) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITabBar class]]) {
                return;
            }
        } else if ([from isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UIBarButtonItem class]]) {
                return;
            }
        } else
#endif
        if ([to isKindOfClass:[UISearchBar class]]) {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UISearchBar class]]) {
                return;
            }
        } else {
            if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[from class]]) {
                return;
            }
        }
        
        /*
         此处不处理 UITabBar，放到 UITabBar+AutoTrack.h 中处理
         */
        if (from != nil) {
            if ([from isKindOfClass:[UIBarButtonItem class]]) {
                return;
            }
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
            if ([from isKindOfClass:[NSClassFromString(@"UITabBarButton") class]]) {
                return;
            }
#else
            if ([to isKindOfClass:[UITabBar class]]) {
                return;
            }
#endif
        }
        
        if (([event isKindOfClass:[UIEvent class]] && event.type==UIEventTypeTouches) ||
            [from isKindOfClass:[UISwitch class]] ||
            [from isKindOfClass:[UIStepper class]] ||
            [from isKindOfClass:[UISegmentedControl class]]) {//0
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
                }
                //再获取 controller.navigationItem.titleView, 并且优先级比较高
                NSString *elementContent = [[SensorsAnalyticsSDK sharedInstance] getUIViewControllerTitle:viewController];
                if (elementContent != nil && [elementContent length] > 0) {
                    elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                    [properties setValue:elementContent forKey:@"$title"];
                }
            }
            
            //UISwitch
            if ([from isKindOfClass:[UISwitch class]]) {
                [properties setValue:@"UISwitch" forKey:@"$element_type"];
                UISwitch *uiSwitch = (UISwitch *)from;
                if (uiSwitch.on) {
                    [properties setValue:@"checked" forKey:@"$element_content"];
                } else {
                    [properties setValue:@"unchecked" forKey:@"$element_content"];
                }
                
                [AutoTrackUtils sa_addViewPathProperties:properties withObject:uiSwitch withViewController:viewController];
                
                //View Properties
                NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
                if (propDict != nil) {
                    [properties addEntriesFromDictionary:propDict];
                }
                [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
                return;
            }

            //UIStepper
            if ([from isKindOfClass:[UIStepper class]]) {
                [properties setValue:@"UIStepper" forKey:@"$element_type"];
                UIStepper *stepper = (UIStepper *)from;
                if (stepper) {
                    [properties setValue:[NSString stringWithFormat:@"%g", stepper.value] forKey:@"$element_content"];
                }
                
                [AutoTrackUtils sa_addViewPathProperties:properties withObject:stepper withViewController:viewController];
                
                //View Properties
                NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
                if (propDict != nil) {
                    [properties addEntriesFromDictionary:propDict];
                }
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
                
                if ([segmented selectedSegmentIndex] == UISegmentedControlNoSegment) {
                    return;
                }
                
                [properties setValue:[NSString stringWithFormat: @"%ld", (long)[segmented selectedSegmentIndex]] forKey:@"$element_position"];
                [properties setValue:[segmented titleForSegmentAtIndex:[segmented selectedSegmentIndex]] forKey:@"$element_content"];
                
                [AutoTrackUtils sa_addViewPathProperties:properties withObject:segmented withViewController:viewController];
                
                //View Properties
                NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
                if (propDict != nil) {
                    [properties addEntriesFromDictionary:propDict];
                }
                [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
                return;
                
            }
            
            //只统计触摸结束时
            if ([event isKindOfClass:[UIEvent class]] && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
                if ([from isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
                    UIButton *button = (UIButton *)from;
                    [properties setValue:@"UIBarButtonItem" forKey:@"$element_type"];
                    if (button != nil) {
                        NSString *currentTitle = [button currentTitle];
                        if (currentTitle != nil) {
                            [properties setValue:[button currentTitle] forKey:@"$element_content"];
                        } else {
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
                            UIImage *image = button.currentImage;
                            if (image) {
                                NSString *imageName = image.sensorsAnalyticsImageName;
                                if (imageName != nil) {
                                    [properties setValue:[NSString stringWithFormat:@"$%@", imageName] forKey:@"$element_content"];
                                }
                            }
#endif
                        }
                    }
                } else
#endif
                if ([from isKindOfClass:[UIButton class]]) {//UIButton
                    UIButton *button = (UIButton *)from;
                    [properties setValue:@"UIButton" forKey:@"$element_type"];
                    if (button != nil) {
                        if ([button currentTitle] != nil) {
                            [properties setValue:[button currentTitle] forKey:@"$element_content"];
                        } else {
                            if (button.subviews.count > 0) {
                                NSString *elementContent = [[NSString alloc] init];
                                elementContent = [AutoTrackUtils contentFromView:button];
                                if (elementContent != nil && [elementContent length] > 0) {
                                    elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                                    [properties setValue:elementContent forKey:@"$element_content"];
                                } else {
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
                                    UIImage *image = button.currentImage;
                                    if (image) {
                                        NSString *imageName = image.sensorsAnalyticsImageName;
                                        if (imageName != nil) {
                                            [properties setValue:[NSString stringWithFormat:@"$%@", imageName] forKey:@"$element_content"];
                                        }
                                    }
#endif
                                }
                            }
                        }
                    }
                }
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
                else if ([from isKindOfClass:[NSClassFromString(@"UITabBarButton") class]]) {//UITabBarButton
                    if ([to isKindOfClass:[UITabBar class]]) {//UITabBar
                        UITabBar *tabBar = (UITabBar *)to;
                        if (tabBar != nil) {
                            UITabBarItem *item = [tabBar selectedItem];
                            [properties setValue:@"UITabbar" forKey:@"$element_type"];
                            [properties setValue:item.title forKey:@"$element_content"];
                        }
                    }
                }
#endif
                else if([from isKindOfClass:[UITabBarItem class]]){//For iOS7 TabBar
                    UITabBarItem *tabBarItem = (UITabBarItem *)from;
                    if (tabBarItem) {
                        [properties setValue:@"UITabbar" forKey:@"$element_type"];
                        [properties setValue:tabBarItem.title forKey:@"$element_content"];
                    }
                } else if ([from isKindOfClass:[UISlider class]]) {//UISlider
                    UISlider *slide = (UISlider *)from;
                    if (slide != nil) {
                        [properties setValue:@"UISlider" forKey:@"$element_type"];
                        [properties setValue:[NSString stringWithFormat:@"%f",slide.value] forKey:@"$element_content"];
                    }
                } else {
                    if ([from isKindOfClass:[UIControl class]]) {
                        [properties setValue:@"UIControl" forKey:@"$element_type"];
                        UIControl *fromView = (UIControl *)from;
                        if (fromView.subviews.count > 0) {
                            NSString *elementContent = [[NSString alloc] init];
                            elementContent = [AutoTrackUtils contentFromView:fromView];
                            if (elementContent != nil && [elementContent length] > 0) {
                                elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                                [properties setValue:elementContent forKey:@"$element_content"];
                            }
                        }
                    }
                }
                
                [AutoTrackUtils sa_addViewPathProperties:properties withObject:view withViewController:viewController];
                
                //View Properties
                NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
                if (propDict != nil) {
                    [properties addEntriesFromDictionary:propDict];
                }
                
                [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
            }
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

@end
