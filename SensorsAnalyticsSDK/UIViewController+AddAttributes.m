//
//  UIViewController+AddAttributes.m
//  SensorsAnalyticsSDK
//
//  Created by Justin.wang on 2018/5/15.
//  Copyright © 2018年 SensorsData. All rights reserved.
//

#import "UIViewController+AddAttributes.h"
#import <objc/runtime.h>

static char *const AddAttributesTitle;

@implementation UIViewController (AddAttributes)

- (void)setSa_title:(NSString *)sa_title {
    objc_setAssociatedObject(self, &AddAttributesTitle, sa_title, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)sa_title {
    NSString *title = objc_getAssociatedObject(self, &AddAttributesTitle);
    return title ?: (self.navigationItem.title ?: self.title);
}

@end
