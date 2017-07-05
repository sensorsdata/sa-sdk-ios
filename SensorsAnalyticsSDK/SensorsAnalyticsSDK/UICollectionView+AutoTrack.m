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
#import "AutoTrackUtils.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UICollectionView (AutoTrack)

#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UICOLLECTIONVIEW

//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        @try {
//            NSError *error = NULL;
//            [[self class] sa_swizzleMethod:@selector(setDelegate:)
//                                withMethod:@selector(sa_collectionViewSetDelegate:)
//                                     error:&error];
//            if (error) {
//                SAError(@"Failed to swizzle setDelegate: on UICollectionView. Details: %@", error);
//                error = NULL;
//            }
//        } @catch (NSException *exception) {
//            SAError(@"%@ error: %@", self, exception);
//        }
//    });
//}

void sa_collectionViewDidSelectItemAtIndexPath(id self, SEL _cmd, id collectionView, NSIndexPath* indexPath) {
    SEL selector = NSSelectorFromString(@"sa_collectionViewDidSelectItemAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, collectionView, indexPath);
    
    //插入埋点
    [AutoTrackUtils trackAppClickWithUICollectionView:collectionView didSelectItemAtIndexPath:indexPath];
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
