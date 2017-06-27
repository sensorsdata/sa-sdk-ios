//
//
//  UITableView+SensorsAnalytics.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 17/3/22.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "UITableView+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UITableView (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UITABLEVIEW

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSError *error = NULL;
            [[self class] sa_swizzleMethod:@selector(setDelegate:)
                                withMethod:@selector(sa_tableViewSetDelegate:)
                                     error:&error];
            if (error) {
                SAError(@"Failed to swizzle setDelegate: on UITableView. Details: %@", error);
                error = NULL;
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
    });
}

void sa_tableViewDidSelectRowAtIndexPath(id self, SEL _cmd, id tableView, NSIndexPath* indexPath) {
    SEL selector = NSSelectorFromString(@"sa_tableViewDidSelectRowAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tableView, indexPath);
    
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
        
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UITableView class]]) {
            return;
        }
        
        if (!tableView) {
            return;
        }
        
        UIView *view = (UIView *)tableView;
        if (!view) {
            return;
        }
        
        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        [properties setValue:@"UITableView" forKey:@"$element_type"];
        
        //ViewID
        if (view.sensorsAnalyticsViewID != nil) {
            [properties setValue:view.sensorsAnalyticsViewID forKey:@"$element_id"];
        }
        
        UIViewController *viewController = [tableView viewController];
        
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
        
        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:@"$element_position"];
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *elementContent = [[NSString alloc] init];
        
        for (UIView *subView in [cell subviews]) {
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
                } else if ([subView isKindOfClass:[NSClassFromString(@"UITableViewCellContentView") class]]){
                    for (UIView *contentView in [subView subviews]) {
                        if (contentView) {
                            if (contentView.sensorsAnalyticsIgnoreView) {
                                continue;
                            }
                            if ([contentView isKindOfClass:[UIButton class]]) {
                                UIButton *button = (UIButton *)contentView;
                                if ([button currentTitle] != nil && ![@"" isEqualToString:[button currentTitle]]) {
                                    elementContent = [elementContent stringByAppendingString:[button currentTitle]];
                                    elementContent = [elementContent stringByAppendingString:@"-"];
                                }
                            } else if ([contentView isKindOfClass:[UILabel class]]) {
                                UILabel *label = (UILabel *)contentView;
                                if (label.text != nil && ![@"" isEqualToString:label.text]) {
                                    elementContent = [elementContent stringByAppendingString:label.text];
                                    elementContent = [elementContent stringByAppendingString:@"-"];
                                }
                            }
                        }
                    }
                }
            }
        }
        if (elementContent != nil && [elementContent length] > 0) {
            elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
            [properties setValue:elementContent forKey:@"$element_content"];
        }
        
        //View Properties
        NSDictionary* propDict = view.sensorsAnalyticsViewProperties;
        if (propDict != nil) {
            [properties addEntriesFromDictionary:propDict];
        }
        
        @try {
            if (view.sensorsAnalyticsDelegate) {
                if ([view.sensorsAnalyticsDelegate conformsToProtocol:@protocol(SAUIViewAutoTrackDelegate)]) {
                    if ([view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_tableView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath]];
                    }
                }
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
        
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" withProperties:properties];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

- (void)sa_tableViewSetDelegate:(id<UITableViewDelegate>)delegate {
    [self sa_tableViewSetDelegate:delegate];
    
    @try {
        Class class = [delegate class];
        //        static dispatch_once_t onceToken;
        //        dispatch_once(&onceToken, ^{
        if (class_addMethod(class, NSSelectorFromString(@"sa_tableViewDidSelectRowAtIndexPath"), (IMP)sa_tableViewDidSelectRowAtIndexPath, "v@:@@")) {
            Method dis_originMethod = class_getInstanceMethod(class, NSSelectorFromString(@"sa_tableViewDidSelectRowAtIndexPath"));
            Method dis_swizzledMethod = class_getInstanceMethod(class, @selector(tableView:didSelectRowAtIndexPath:));
            method_exchangeImplementations(dis_originMethod, dis_swizzledMethod);
        }
        //        });
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

#endif

@end
