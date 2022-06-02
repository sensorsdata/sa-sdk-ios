//
// SAOldCellClickPlugin.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/11/8.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SACellClickHookDelegatePlugin.h"
#import "SensorsAnalyticsSDK.h"
#import "SAAutoTrackUtils.h"
#import "SAAutoTrackManager.h"
#import "SASwizzle.h"
#import <objc/message.h>

static NSString *const kSAEventTrackerPluginType = @"AppClick+ScrollView";

static void sa_tablViewDidSelectRowAtIndexPath(id self, SEL _cmd, id tableView, id indexPath) {
    SEL selector = NSSelectorFromString(@"sa_tableView:didSelectRowAtIndexPath:");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tableView, indexPath);
    [SAAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithScrollView:tableView atIndexPath:indexPath];
}

static void sa_collectionViewDidSelectItemAtIndexPath(id self, SEL _cmd, id collectionView, id indexPath) {
    SEL selector = NSSelectorFromString(@"sa_collectionView:didSelectItemAtIndexPath:");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, collectionView, indexPath);
    [SAAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithScrollView:collectionView atIndexPath:indexPath];
}

@implementation SACellClickHookDelegatePlugin

- (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod];
    });
    self.enable = YES;
}

- (void)uninstall {
    self.enable = NO;
}

- (NSString *)type {
    return kSAEventTrackerPluginType;
}

- (void)swizzleMethod {
    SEL selector = NSSelectorFromString(@"sensorsdata_old_setDelegate:");
    [UITableView sa_swizzleMethod:@selector(setDelegate:)
                       withMethod:selector
                            error:NULL];
    [UICollectionView sa_swizzleMethod:@selector(setDelegate:)
                            withMethod:selector
                                 error:NULL];
}

+ (void)hookDelegate:(id)delegate forObject:(id)object {
    if ([object isKindOfClass:UITableView.class]) {
        if ([delegate isKindOfClass:[UITableView class]]) {
            return;
        }
        Class class = [delegate class];
        do {
            Method rootMethod = nil;
            if ((rootMethod = class_getInstanceMethod(class, @selector(tableView:didSelectRowAtIndexPath:)))) {
                if (!class_getInstanceMethod(class_getSuperclass(class), @selector(tableView:didSelectRowAtIndexPath:))) {
                    const char* encoding = method_getTypeEncoding(rootMethod);
                    SEL swizSel = NSSelectorFromString(@"sa_tableView:didSelectRowAtIndexPath:");
                    if (class_addMethod(class , swizSel, (IMP)sa_tablViewDidSelectRowAtIndexPath, encoding)) {
                        Method originalMethod = class_getInstanceMethod(class, @selector(tableView:didSelectRowAtIndexPath:));
                        Method swizzledMethod = class_getInstanceMethod(class, swizSel);
                        method_exchangeImplementations(originalMethod, swizzledMethod);
                    }
                    break;
                }
            }
        } while ((class = class_getSuperclass(class)));
    } else if ([object isKindOfClass:UICollectionView.class]) {
        if ([delegate isKindOfClass:[UICollectionView class]]) {
            return;
        }
        Class class = [delegate class];
        do {
            Method rootMethod = nil;
            if ((rootMethod = class_getInstanceMethod(class, @selector(collectionView:didSelectItemAtIndexPath:)))) {
                if (!class_getInstanceMethod(class_getSuperclass(class), @selector(collectionView:didSelectItemAtIndexPath:))) {
                    const char* encoding = method_getTypeEncoding(rootMethod);
                    SEL swizSel = NSSelectorFromString(@"sa_collectionView:didSelectItemAtIndexPath:");
                    if (class_addMethod(class, swizSel, (IMP)sa_collectionViewDidSelectItemAtIndexPath, encoding)) {
                        Method originalMethod = class_getInstanceMethod(class, @selector(collectionView:didSelectItemAtIndexPath:));
                        Method swizzledMethod = class_getInstanceMethod(class, swizSel);
                        method_exchangeImplementations(originalMethod, swizzledMethod);
                    }
                    break;
                }
            }
        } while ((class = class_getSuperclass(class)));
    }
}

@end
