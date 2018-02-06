//
//  UIImage.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/6/13.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "UIImage+AutoTrack.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"
#import "SASwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UIImage (AutoTrack)
#ifndef SENSORS_ANALYTICS_DISABLE_AUTOTRACK_UIIMAGE_IMAGENAME
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        @try {
//            Class selfClass = object_getClass([self class]);
//
//            SEL oriSEL = @selector(imageNamed:);
//            Method oriMethod = class_getInstanceMethod(selfClass, oriSEL);
//
//            SEL cusSEL = @selector(myImageNamed:);
//            Method cusMethod = class_getInstanceMethod(selfClass, cusSEL);
//
//            BOOL addSucc = class_addMethod(selfClass, oriSEL, method_getImplementation(cusMethod), method_getTypeEncoding(cusMethod));
//            if (addSucc) {
//                class_replaceMethod(selfClass, cusSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
//            }else {
//                method_exchangeImplementations(oriMethod, cusMethod);
//            }
//        } @catch (NSException *exception) {
//            SAError(@"%@ error: %@", self, exception);
//        }
//    });
//}
//
//+ (UIImage *)myImageNamed:(NSString *)name {
//    __block UIImage *image;
//    if ([[NSThread currentThread] isMainThread]) {
//        image = [self myImageNamed:name];
//        image.sensorsAnalyticsImageName = name;
//    } else {
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            image = [self myImageNamed:name];
//            image.sensorsAnalyticsImageName = name;
//        });
//    }
//    return image;
//}

#endif

@end
