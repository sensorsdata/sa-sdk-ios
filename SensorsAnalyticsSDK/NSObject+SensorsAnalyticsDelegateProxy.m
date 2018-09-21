//
//  NSObject+SensorsAnalyticsDelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "NSObject+SensorsAnalyticsDelegateProxy.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import <objc/message.h>
#import "SADelegateProxy.h"
void sa_setDelegate(id obj ,SEL sel, id delegate){
    SEL swizzileSel = sel_getUid("sa_setDelegate:");
    if (delegate != nil) {
        SADelegateProxy *delegateProxy = nil;
        if ([obj isKindOfClass:UITableView.class]) {
            delegateProxy = [SADelegateProxy proxyWithTableView:delegate];
        }else if ([obj isKindOfClass:UICollectionView.class]){
            delegateProxy = [SADelegateProxy proxyWithCollectionView:delegate];
        }
        delegate = delegateProxy;
    }
    [(NSObject *)obj setSensorsAnalyticsDelegateProxy:delegate];
    ((void (*)(id, SEL,id))objc_msgSend)(obj,swizzileSel,delegate);
}

@implementation NSObject (SensorsAnalyticsDelegateProxy)

-(void)setSensorsAnalyticsDelegateProxy:(SADelegateProxy *)SensorsAnalyticsDelegateProxy{
    objc_setAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:), SensorsAnalyticsDelegateProxy, OBJC_ASSOCIATION_RETAIN);
}
-(SADelegateProxy *)sensorsAnalyticsDelegateProxy{
    return objc_getAssociatedObject(self, @selector(setSensorsAnalyticsDelegateProxy:));
}

@end

@implementation UITableView (SensorsAnalyticsDelegateProxy)
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

@implementation UICollectionView (SensorsAnalyticsDelegateProxy)
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

