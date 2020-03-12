//
//  SAApplicationStateSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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


#import <QuartzCore/QuartzCore.h>
#import "SAApplicationStateSerializer.h"
#import "SAClassDescription.h"
#import "SALogger.h"
#import "SAObjectIdentityProvider.h"
#import "SAHeatMapObjectSerializer.h"
#import "SAVisualizedAutoTrackObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAAuxiliaryToolManager.h"

@implementation SAApplicationStateSerializer {
    SAHeatMapObjectSerializer *_heatmapSerializer;
    SAVisualizedAutoTrackObjectSerializer *_visualizedAutoTrackSerializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application
                      configuration:(SAObjectSerializerConfig *)configuration
             objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    NSParameterAssert(application != nil);
    NSParameterAssert(configuration != nil);
    if (!application || !configuration) {
        return nil;
    }
    self = [super init];
    if (self) {
        _application = application;
        _heatmapSerializer = [[SAHeatMapObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
        _visualizedAutoTrackSerializer = [[SAVisualizedAutoTrackObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }
    
    return self;
}


- (UIImage *)screenshotImageForKeyWindow {
    UIImage *image = nil;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIWindow *mainWindow = [self uiMainWindow:keyWindow];
    if (mainWindow && !CGRectEqualToRect(mainWindow.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(mainWindow.bounds.size, YES, mainWindow.screen.scale);
        if ([mainWindow respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            if (![mainWindow drawViewHierarchyInRect:mainWindow.bounds afterScreenUpdates:NO]) {
                SAError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
        } else {
            [mainWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

// 所有 window 截图合成
- (void)screenshotImageForAllWindowWithCompletionHandler:(void (^)(UIImage *))completionHandler {
    CGFloat scale = [UIScreen mainScreen].scale;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIWindow *firstWindow = [UIApplication sharedApplication].windows.firstObject;

    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    UIImage *image = [self screenshotWithView:keyWindow afterScreenUpdates:NO];
    if (image) {
        [images addObject:image];
    }
    // 如果 firstWindow 和 keyWindow 不同，则包含弹框或其他多 window，并设置为 keyWindow
    if (firstWindow != keyWindow) {
        UIImage *image = [self screenshotWithView:firstWindow afterScreenUpdates:NO];
        if (image) {
            [images insertObject:image atIndex:0];
        }
    }

    if (images.count == 1) {
        // 单张图片
        completionHandler(images.firstObject);
    } else {
        // 子线程异步绘图合成
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 将上面得到的多张图片合并绘制为一张图片，最终得到 screenshotImage
            UIImage *screenshotImage = nil;
            if (images.count > 0) {
                CGSize newSize = CGSizeMake(images.firstObject.size.width * scale, images.firstObject.size.height * scale);
                UIGraphicsBeginImageContext(newSize);
                for (UIImage *image in images) {
                    [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
                }
                screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            // 绘制操作完成
            completionHandler(screenshotImage);
        });
    }
}

// 对 view 截图
- (UIImage *)screenshotWithView:(UIView *)currentView afterScreenUpdates:(BOOL)afterUpdates {
    if (!currentView || ![currentView isKindOfClass:UIView.class]) {
        return nil;
    }
    UIImage *screenshotImage = nil;
    @try {
        CGSize size = currentView.bounds.size;
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        CGRect rect = currentView.frame;
        //  drawViewHierarchyInRect:afterScreenUpdates: 截取一个UIView或者其子类中的内容，并且以位图的形式（bitmap）保存到UIImage中
        [currentView drawViewHierarchyInRect:rect afterScreenUpdates:afterUpdates];
        screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } @catch (NSException *exception) {
        SAError(@"screenshot fail，error %@: %@", self, exception);
    }
    return screenshotImage;
}

- (UIWindow *)uiMainWindow:(UIWindow *)window {
    if (window != nil) {
        return window;
    }
    return _application.windows[0];
}

- (NSDictionary *)objectHierarchyForWindow:(UIWindow *)window {
    UIWindow *mainWindow = [self uiMainWindow:window];
    if (mainWindow) {
        // 点击图
        if ([SAAuxiliaryToolManager sharedInstance].currentVisualizedType == SensorsAnalyticsVisualizedTypeHeatMap) {
            return [_heatmapSerializer serializedObjectsWithRootObject:mainWindow];
            
            // 可视化全埋点
        } else if ([SAAuxiliaryToolManager sharedInstance].currentVisualizedType == SensorsAnalyticsVisualizedTypeAutoTrack) {
            return [_visualizedAutoTrackSerializer serializedObjectsWithRootObject:mainWindow];
        }
    }
    
    return @{};
}

@end
