//
//  AutoTrackUtils.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/29.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "AutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "UIView+SAHelpers.h"

@implementation AutoTrackUtils

+ (void)sa_find_view_responder:(UIView *)view withViewPathArray:(NSMutableArray *)viewPathArray {
    NSMutableArray *viewVarArray = [[NSMutableArray alloc] init];
    NSString *varE = [view jjf_varE];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varE='%@'", varE]];
    }
    //    NSArray *varD = [view jjf_varSetD];
    //    if (varD != nil && [varD count] > 0) {
    //        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varSetD='%@'", [varD componentsJoinedByString:@","]]];
    //    }
    varE = [view jjf_varC];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varC='%@'", varE]];
    }
    varE = [view jjf_varB];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varB='%@'", varE]];
    }
    varE = [view jjf_varA];
    if (varE != nil) {
        [viewVarArray addObject:[NSString stringWithFormat:@"jjf_varA='%@'", varE]];
    }
    if ([viewVarArray count] == 0) {
        long count = 0;
        NSArray<__kindof UIView *> *subviews;
        NSMutableArray<__kindof UIView *> *sameTypeViews = [[NSMutableArray alloc] init];
        id nextResponder = [view nextResponder];
        if (nextResponder) {
            if ([nextResponder respondsToSelector:NSSelectorFromString(@"subviews")]) {
                subviews = [nextResponder subviews];
                if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UICollectionView class]]) {
                    subviews =  [[subviews reverseObjectEnumerator] allObjects];
                }
            }

            for (UIView *v in subviews) {
                if (v) {
                    if ([NSStringFromClass([view class]) isEqualToString:NSStringFromClass([v class])]) {
                        [sameTypeViews addObject:v];
                    }
                }
            }
            count = (unsigned long)subviews.count;
        }
        if (sameTypeViews.count > 1) {
            NSString * className = nil;
            NSUInteger index = [sameTypeViews indexOfObject:view];
            className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([view class]), index];
            [viewPathArray addObject:className];
        } else {
            [viewPathArray addObject:NSStringFromClass([view class])];
        }
    } else {
        NSString *viewIdentify = [NSString stringWithString:NSStringFromClass([view class])];
        viewIdentify = [viewIdentify stringByAppendingString:@"[("];
        for (int i = 0; i < viewVarArray.count; i++) {
            viewIdentify = [viewIdentify stringByAppendingString:viewVarArray[i]];
            if (i != (viewVarArray.count - 1)) {
                viewIdentify = [viewIdentify stringByAppendingString:@" AND "];
            }
        }
        viewIdentify = [viewIdentify stringByAppendingString:@")]"];
        [viewPathArray addObject:viewIdentify];
    }
}

+ (void)sa_find_responder:(id)responder withViewPathArray:(NSMutableArray *)viewPathArray {

    while (responder!=nil&&![responder isKindOfClass:[UIViewController class]] &&
           ![responder isKindOfClass:[UIWindow class]]) {
        long count = 0;
        NSArray<__kindof UIView *> *subviews;
        id nextResponder = [responder nextResponder];
        if (nextResponder) {
            if ([nextResponder respondsToSelector:NSSelectorFromString(@"subviews")]) {
                subviews = [nextResponder subviews];
                if ([responder isKindOfClass:[UITableView class]] || [responder isKindOfClass:[UICollectionView class]]) {
                    subviews =  [[subviews reverseObjectEnumerator] allObjects];
                }
                if (subviews) {
                    count = (unsigned long)subviews.count;
                }
            }
        }
        if (count <= 1) {
            if (NSStringFromClass([responder class])) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            }
        } else {
            NSMutableArray<__kindof UIView *> *sameTypeViews = [[NSMutableArray alloc] init];
            for (UIView *v in subviews) {
                if (v) {
                    if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([v class])]) {
                        [sameTypeViews addObject:v];
                    }
                }
            }
            if (sameTypeViews.count > 1) {
                NSString * className = nil;
                NSUInteger index = [sameTypeViews indexOfObject:responder];
                className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), index];
                [viewPathArray addObject:className];
            } else {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            }
        }
        
        responder = [responder nextResponder];
    }
    
    if (responder && [responder isKindOfClass:[UIViewController class]]) {
        while ([responder parentViewController]) {
            UIViewController *viewController = [responder parentViewController];
            if (viewController) {
                NSArray<__kindof UIViewController *> *childViewControllers = [viewController childViewControllers];
                if (childViewControllers > 0) {
                    NSMutableArray<__kindof UIViewController *> *items = [[NSMutableArray alloc] init];
                    for (UIViewController *v in childViewControllers) {
                        if (v) {
                            if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([v class])]) {
                                [items addObject:v];
                            }
                        }
                    }
                    if (items.count > 1) {
                        NSString * className = nil;
                        NSUInteger index = [items indexOfObject:responder];
                        className = [NSString stringWithFormat:@"%@[%lu]", NSStringFromClass([responder class]), index];
                        [viewPathArray addObject:className];
                    } else {
                        [viewPathArray addObject:NSStringFromClass([responder class])];
                    }
                } else {
                    [viewPathArray addObject:NSStringFromClass([responder class])];
                }
                
                responder = viewController;
            }
        }
        [viewPathArray addObject:NSStringFromClass([responder class])];
    }
}

+ (NSString *)contentFromView:(UIView *)rootView {
    @try {
        NSMutableString *elementContent = [NSMutableString string];
        for (UIView *subView in [rootView subviews]) {
            if (subView) {
                if (subView.sensorsAnalyticsIgnoreView) {
                    continue;
                }

                if (subView.isHidden) {
                    continue;
                }

                if ([subView isKindOfClass:[UIButton class]]) {
                    UIButton *button = (UIButton *)subView;
                    if ([button currentTitle] != nil && ![@"" isEqualToString:[button currentTitle]]) {
                        [elementContent appendString:[button currentTitle]];
                        [elementContent appendString:@"-"];
                    }
                } else if ([subView isKindOfClass:[UILabel class]]) {
                    UILabel *label = (UILabel *)subView;
                    if (label.text != nil && ![@"" isEqualToString:label.text]) {
                        [elementContent appendString:label.text];
                        [elementContent appendString:@"-"];
                    }
                } else if ([subView isKindOfClass:[UITextView class]]) {
                    UITextView *textView = (UITextView *)subView;
                    if (textView.text != nil && ![@"" isEqualToString:textView.text]) {
                        [elementContent appendString:textView.text];
                        [elementContent appendString:@"-"];
                    }
                } else if ([subView isKindOfClass:NSClassFromString(@"RTLabel")]) {//RTLabel:https://github.com/honcheng/RTLabel
                    #pragma clang diagnostic push
                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    if ([subView respondsToSelector:NSSelectorFromString(@"text")]) {
                        NSString *title = [subView performSelector:NSSelectorFromString(@"text")];
                        if (title != nil && ![@"" isEqualToString:title]) {
                            [elementContent appendString:title];
                            [elementContent appendString:@"-"];
                        }
                    }
                    #pragma clang diagnostic pop
                } else if ([subView isKindOfClass:NSClassFromString(@"YYLabel")]) {//RTLabel:https://github.com/ibireme/YYKit
                    #pragma clang diagnostic push
                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    if ([subView respondsToSelector:NSSelectorFromString(@"text")]) {
                        NSString *title = [subView performSelector:NSSelectorFromString(@"text")];
                        if (title != nil && ![@"" isEqualToString:title]) {
                            [elementContent appendString:title];
                            [elementContent appendString:@"-"];
                        }
                    }
                    #pragma clang diagnostic pop
                }
#if (defined SENSORS_ANALYTICS_ENABLE_NO_PUBLICK_APIS)
                else if ([subView isKindOfClass:[NSClassFromString(@"UITableViewCellContentView") class]] ||
                            [subView isKindOfClass:[NSClassFromString(@"UICollectionViewCellContentView") class]] ||
                            subView.subviews.count > 0){
                    NSString *temp = [self contentFromView:subView];
                    if (temp != nil && ![@"" isEqualToString:temp]) {
                        [elementContent appendString:temp];
                    }
                }
#else
                else {
                    NSString *temp = [self contentFromView:subView];
                    if (temp != nil && ![@"" isEqualToString:temp]) {
                        [elementContent appendString:temp];
                    }
                }
#endif
            }
        }
        return elementContent;
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
        return nil;
    }
}

+ (void)trackAppClickWithUICollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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
            }
            NSString *elementContent = [[SensorsAnalyticsSDK sharedInstance] getUIViewControllerTitle:viewController];
            if (elementContent != nil && [elementContent length] > 0) {
                elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                [properties setValue:elementContent forKey:@"$title"];
            }
        }

        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:@"$element_position"];
        }

        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (cell==nil) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
        NSString *cellClass =NSStringFromClass([cell class]);
        
        if ([[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled] && [[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
            long section = (unsigned long)indexPath.section;
            int count = 0;
            for (int i = 0; i <= section; i++) {
                NSInteger numberOfItemsInSection = [collectionView numberOfItemsInSection:i];
                if (i == section) {
                    numberOfItemsInSection = indexPath.row;
                }
                for (int j = 0; j < numberOfItemsInSection; j++) {
                    UICollectionViewCell *cellRow = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                    if(cellRow == nil) {
                        [collectionView layoutIfNeeded];
                        cellRow = [collectionView cellForItemAtIndexPath:indexPath];
                    }
                    if(cellRow == nil) {
                        [collectionView reloadData];
                        [collectionView layoutIfNeeded];
                        cellRow = [collectionView cellForItemAtIndexPath:indexPath];
                    }
                    if ([cellClass isEqualToString:NSStringFromClass([cellRow class])]) {
                        count++;
                    }
                }
            }
            [viewPathArray addObject:[NSString stringWithFormat:@"%@[%d]",NSStringFromClass([cell class]), count]];
            id responder = cell.nextResponder;
            
            NSArray<__kindof UIView *> *subviews = [collectionView.superview subviews];
            NSMutableArray<__kindof UIView *> *viewsArray = [[NSMutableArray alloc] init];
            for (UIView *obj in subviews) {
                if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([obj class])]) {
                    [viewsArray addObject:obj];
                }
            }
            
            if ([viewsArray count] == 1) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            } else {
                NSInteger index = [viewsArray indexOfObject:collectionView];
                [viewPathArray addObject:[NSString stringWithFormat:@"%@[%ld]", NSStringFromClass([responder class]), index]];
            }
            
            responder = [responder nextResponder];
            [self sa_find_responder:responder withViewPathArray:viewPathArray];

            NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];

            NSString *viewPath = [[NSString alloc] init];
            for (int i = 0; i < array.count; i++) {
                viewPath = [viewPath stringByAppendingString:array[i]];
                if (i != (array.count - 1)) {
                    viewPath = [viewPath stringByAppendingString:@"/"];
                }
            }
            [properties setValue:viewPath forKey:@"$element_selector"];
        }
        
        NSString *elementContent = [[NSString alloc] init];
        elementContent = [self contentFromView:cell];
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

+ (void)trackAppClickWithUITableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
            }

            NSString *elementContent = [[SensorsAnalyticsSDK sharedInstance] getUIViewControllerTitle:viewController];
            if (elementContent != nil && [elementContent length] > 0) {
                elementContent = [elementContent substringWithRange:NSMakeRange(0,[elementContent length] - 1)];
                [properties setValue:elementContent forKey:@"$title"];
            }
        }

        if (indexPath) {
            [properties setValue:[NSString stringWithFormat: @"%ld:%ld", (unsigned long)indexPath.section,(unsigned long)indexPath.row] forKey:@"$element_position"];
        }

        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell == nil) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
        NSString *cellClass =NSStringFromClass([cell class]);
        NSString *elementContent = [[NSString alloc] init];

        if ([[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled] && [[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];
            long section = (unsigned long)indexPath.section;
            int count = 0;
            for (int i = 0; i <= section; i++) {
                NSInteger numberOfItemsInSection = [tableView numberOfRowsInSection:i];
                if (i == section) {
                    numberOfItemsInSection = indexPath.row;
                }
                for (int j = 0; j < numberOfItemsInSection; j++) {
                    UITableViewCell *cellRow = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                    if(cellRow == nil) {
                        [tableView layoutIfNeeded];
                        cellRow = [tableView cellForRowAtIndexPath:indexPath];
                    }
                    if(cellRow == nil) {
                        [tableView reloadData];
                        [tableView layoutIfNeeded];
                        cellRow = [tableView cellForRowAtIndexPath:indexPath];
                    }
                    if ([cellClass isEqualToString:NSStringFromClass([cellRow class])]) {
                        count++;
                    }
                }
            }
            [viewPathArray addObject:[NSString stringWithFormat:@"%@[%d]",NSStringFromClass([cell class]), count]];
            id responder = cell.nextResponder;
            NSArray<__kindof UIView *> *subviews = [tableView.superview subviews];
            NSMutableArray<__kindof UIView *> *viewsArray = [[NSMutableArray alloc] init];
            for (UIView *obj in subviews) {
                if ([NSStringFromClass([responder class]) isEqualToString:NSStringFromClass([obj class])]) {
                    [viewsArray addObject:obj];
                }
            }
            if ([viewsArray count] == 1) {
                [viewPathArray addObject:NSStringFromClass([responder class])];
            } else {
                NSInteger index = [viewsArray indexOfObject:tableView];
                [viewPathArray addObject:[NSString stringWithFormat:@"%@[%ld]", NSStringFromClass([responder class]), index]];
            }
            responder = [responder nextResponder];
            [self sa_find_responder:responder withViewPathArray:viewPathArray];

            NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];

            NSMutableString *viewPath = [[NSMutableString alloc] init];
            for (int i = 0; i < array.count; i++) {
                [viewPath appendString:array[i]];
                if (i != (array.count - 1)) {
                    [viewPath appendString:@"/"];
                }
            }
            NSRange range = [viewPath rangeOfString:@"UITableViewWrapperView/"];
            if (range.length) {
                [viewPath deleteCharactersInRange:range];
            }
            [properties setValue:viewPath forKey:@"$element_selector"];
        }

        elementContent = [self contentFromView:cell];
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

+ (void)sa_addViewPathProperties:(NSMutableDictionary *)properties withObject:(UIView *)view withViewController:(UIViewController *)viewController {
    @try {
        if (![[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled]) {
            return;
        }

        if (![[SensorsAnalyticsSDK sharedInstance] isHeatMapViewController:viewController]) {
            return;
        }

        NSMutableArray *viewPathArray = [[NSMutableArray alloc] init];

        [self sa_find_view_responder:view withViewPathArray:viewPathArray];
        
        id responder = view.nextResponder;
        [self sa_find_responder:responder withViewPathArray:viewPathArray];
        
        NSArray *array = [[viewPathArray reverseObjectEnumerator] allObjects];
        
        NSString *viewPath = [[NSString alloc] init];
        for (int i = 0; i < array.count; i++) {
            viewPath = [viewPath stringByAppendingString:array[i]];
            if (i != (array.count - 1)) {
                viewPath = [viewPath stringByAppendingString:@"/"];
            }
        }
        [properties setValue:viewPath forKey:@"$element_selector"];
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
}

@end

