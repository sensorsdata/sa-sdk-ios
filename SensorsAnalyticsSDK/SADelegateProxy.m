//
//  SADelegateProxy.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/8.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SADelegateProxy.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
@interface SATableViewDelegateProxy:SADelegateProxy<UITableViewDelegate>
@end
@implementation SATableViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.target respondsToSelector:_cmd]) {
        [SensorsAnalyticsSDK.sharedInstance tableView:tableView didSelectRowAtIndexPath:indexPath];
        [self.target tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}
@end
@interface SACollectionViewDelegateProxy:SADelegateProxy<UICollectionViewDelegate>
@end
@implementation SACollectionViewDelegateProxy
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.target respondsToSelector:_cmd]) {
        [SensorsAnalyticsSDK.sharedInstance collectionView:collectionView didSelectItemAtIndexPath:indexPath];
        [self.target collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}
@end

@implementation SADelegateProxy
+(instancetype)proxyWithTableView:(id)target {
    SATableViewDelegateProxy *delegateProxy = [[SATableViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

+(instancetype)proxyWithCollectionView:(id)target {
    SACollectionViewDelegateProxy *delegateProxy = [[SACollectionViewDelegateProxy alloc]initWithObject:target];
    return delegateProxy;
}

- (id)initWithObject:(id)object {
    self.target = object;
    return self;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [self.target methodSignatureForSelector:selector];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
   
}

-(BOOL)respondsToSelector:(SEL)aSelector{
    if (aSelector == @selector(tableView:didSelectRowAtIndexPath:)) {
        return YES;
    }
    if (aSelector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        return YES;
    }
    return [self.target respondsToSelector:aSelector];
}

-(void)dealloc {
    self.target = nil;
}
@end


