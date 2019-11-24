//
//  NSObject+SensorsAnalyticsDelegate.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#ifdef SENSORS_ANALYTICS_ENABLE_AUTOTRACK_DIDSELECTROW

#import "NSObject+SensorsAnalyticsDelegate.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/message.h>
#import "SAAutoTrackUtils.h"
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"
#import "SensorsAnalyticsSDK+Private.h"

static void sa_tablViewDidSelectRowAtIndexPath(id self, SEL _cmd, id tableView, id indexPath) {
    SEL selector = NSSelectorFromString(@"sa_tableView:didSelectRowAtIndexPath:");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tableView, indexPath);
    
    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:(UITableView<SAAutoTrackViewProperty> *)tableView didSelectedAtIndexPath:indexPath];
    
    if (!properties) {
        return;
    }
    [properties addEntriesFromDictionary:[SAAutoTrackUtils propertiesWithAutoTrackDelegate:tableView didSelectedAtIndexPath:indexPath]];
    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
}

static void sa_collectionViewDidSelectItemAtIndexPath(id self, SEL _cmd, id collectionView, id indexPath) {
    SEL selector = NSSelectorFromString(@"sa_collectionView:didSelectItemAtIndexPath:");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, collectionView, indexPath);
    
      NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:(UICollectionView<SAAutoTrackViewProperty> *)collectionView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return;
    }
    [properties addEntriesFromDictionary:[SAAutoTrackUtils propertiesWithAutoTrackDelegate:collectionView didSelectedAtIndexPath:indexPath]];
    [[SensorsAnalyticsSDK sharedInstance] track:SA_EVENT_NAME_APP_CLICK withProperties:properties withTrackType:SensorsAnalyticsTrackTypeAuto];
}

static void sa_setDelegate(id obj , SEL sel, id delegate) {
    SEL swizzileSel = sel_getUid("sa_setDelegate:");
    ((void (*)(id, SEL, id))objc_msgSend)(obj, swizzileSel, delegate);
    if (delegate == nil) {
        return;
    }
    if ([[SensorsAnalyticsSDK sharedInstance] isAutoTrackEnabled]) {
        if ([obj isKindOfClass:UITableView.class]) {
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
        } else if ([obj isKindOfClass:UICollectionView.class]) {
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
}

@implementation UITableView (SensorsAnalyticsDelegate)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

@implementation UICollectionView (SensorsAnalyticsDelegate)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origSel_ = sel_getUid("setDelegate:");
        SEL swizzileSel = sel_getUid("sa_setDelegate:");
        Method origMethod = class_getInstanceMethod(self, origSel_);
        const char* type = method_getTypeEncoding(origMethod);
        class_addMethod(self, swizzileSel, (IMP)sa_setDelegate, type);
        Method swizzleMethod = class_getInstanceMethod(self, swizzileSel);
        IMP origIMP = method_getImplementation(origMethod);
        IMP swizzleIMP = method_getImplementation(swizzleMethod);
        method_setImplementation(origMethod, swizzleIMP);
        method_setImplementation(swizzleMethod, origIMP);
    });
}

@end

#endif
