//
//  UICollectionView+SensorsAnalytics.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 17/3/22.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "UICollectionView+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SASwizzle.h"
#import "SALogger.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UICollectionView (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSError *error = NULL;
            [[self class] sa_swizzleMethod:@selector(setDelegate:)
                                withMethod:@selector(sa_collectionViewSetDelegate:)
                                     error:&error];
            if (error) {
                SAError(@"Failed to swizzle setDelegate: on UICollectionView. Details: %@", error);
                error = NULL;
            }
        } @catch (NSException *exception) {
            SAError(@"%@ error: %@", self, exception);
        }
    });
}

void sa_collectionViewDidSelectItemAtIndexPath(id self, SEL _cmd, id collectionView, NSIndexPath* indexPath) {
    SEL selector = NSSelectorFromString(@"sa_collectionViewDidSelectItemAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, collectionView, indexPath);
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
        
        if ([[SensorsAnalyticsSDK sharedInstance] isViewTypeIgnored:[UICollectionView class]]) {
            return;
        }
        
        if (!collectionView) {
            return;
        }
        
        UIView *view = (UIView *)collectionView;
        if (!view) {
            return;
        }
        
        if (view.sensorsAnalyticsIgnoreView) {
            return;
        }
        
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        
        [properties setValue:@"UICollectionView" forKey:@"$element_type"];
        
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
        
        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:@"$element_position"];
        }
        
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        NSString *elementContent = [[NSString alloc] init];;
        
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
                    if (label.text != nil && ![@"" isEqualToString:[label text]] ) {
                        elementContent = [elementContent stringByAppendingString:label.text];
                        elementContent = [elementContent stringByAppendingString:@"-"];
                    }
                } else if ([subView isKindOfClass:[NSClassFromString(@"UICollectionViewCellContentView") class]]){
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
                    if ([view.sensorsAnalyticsDelegate respondsToSelector:@selector(sensorsAnalytics_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                        [properties addEntriesFromDictionary:[view.sensorsAnalyticsDelegate sensorsAnalytics_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath]];
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

- (void)sa_collectionViewSetDelegate:(id<UICollectionViewDelegate>)delegate {
    [self sa_collectionViewSetDelegate:delegate];
    
    @try {
        Class class = [delegate class];
        
        if (class_addMethod(class, NSSelectorFromString(@"sa_collectionViewDidSelectItemAtIndexPath"), (IMP)sa_collectionViewDidSelectItemAtIndexPath, "v@:@@")) {
            Method dis_originMethod = class_getInstanceMethod(class, NSSelectorFromString(@"sa_collectionViewDidSelectItemAtIndexPath"));
            Method dis_swizzledMethod = class_getInstanceMethod(class, @selector(collectionView:didSelectItemAtIndexPath:));
            method_exchangeImplementations(dis_originMethod, dis_swizzledMethod);
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

#endif

@end
