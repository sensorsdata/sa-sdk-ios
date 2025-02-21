//
// UIView+ExposureIdentifier.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/22.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+ExposureIdentifier.h"
#import <objc/runtime.h>

static void *const kSAUIViewExposureIdentifierKey = (void *)&kSAUIViewExposureIdentifierKey;

@implementation UIView (SAExposureIdentifier)

- (NSString *)exposureIdentifier {
    return objc_getAssociatedObject(self, kSAUIViewExposureIdentifierKey);
}

- (void)setExposureIdentifier:(NSString *)exposureIdentifier {
    objc_setAssociatedObject(self, kSAUIViewExposureIdentifierKey, exposureIdentifier, OBJC_ASSOCIATION_COPY);
}



@end
