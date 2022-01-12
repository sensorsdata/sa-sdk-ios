//
// SAApplicationStateSerializer.m
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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

#import "SAApplicationStateSerializer.h"
#import "SAClassDescription.h"
#import "SALog.h"
#import "SAObjectIdentityProvider.h"
#import "SAVisualizedAutoTrackObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAVisualizedUtils.h"

@implementation SAApplicationStateSerializer {
    SAVisualizedAutoTrackObjectSerializer *_visualizedSerializer;
}

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
               objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    NSParameterAssert(configuration);
    if (!configuration) {
        return nil;
    }
    self = [super init];
    if (self) {
        _visualizedSerializer = [[SAVisualizedAutoTrackObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }
    
    return self;
}

// 所有 window 截图合成
- (void)screenshotImageForAllWindowWithCompletionHandler:(void (^)(UIImage *))completionHandler {
    CGFloat scale = [UIScreen mainScreen].scale;
    // 获取所有可见的 window 截图
    NSMutableArray <UIWindow *> *allActiveWindows = [NSMutableArray array];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in UIApplication.sharedApplication.connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                [allActiveWindows addObjectsFromArray:windowScene.windows];
            }
        }
    }
#endif
    if (allActiveWindows.count == 0) {
        [allActiveWindows addObjectsFromArray:UIApplication.sharedApplication.windows];
    }

    NSMutableArray <UIWindow *> *validWindows = [NSMutableArray array];
    for (UIWindow *window in allActiveWindows) {
        // 如果 window.superview 存在，则 window 最终被添加在 keyWindow 上，不需要再截图
        if ([SAVisualizedUtils isVisibleForView:window] && !window.superview) {
            [validWindows addObject:window];
        }
    }

    if (validWindows.count == 0) {
        completionHandler(nil);
        return;
    }
    if (validWindows.count == 1) {
        UIImage *image = [SAVisualizedUtils screenshotWithView:validWindows.firstObject];
        // 单张图片
        completionHandler(image);
        return;
    }

    CGSize mainScreenSize = UIScreen.mainScreen.bounds.size;
    CGSize newSize = CGSizeMake(mainScreenSize.width * scale, mainScreenSize.height * scale);
    // 将上面得到的多张图片合并绘制为一张图片，最终得到 screenshotImage
    UIImage *screenshotImage = nil;
    UIGraphicsBeginImageContext(newSize);
    for (UIWindow *window in validWindows) {
        UIImage *image = [SAVisualizedUtils screenshotWithView:window];
        if (image) {
            CGPoint windowPoint = window.frame.origin;
            [image drawInRect:CGRectMake(windowPoint.x * scale, windowPoint.y * scale, image.size.width * scale, image.size.height * scale)];
        }
    }
    screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 绘制操作完成
    completionHandler(screenshotImage);
}

- (NSDictionary *)objectHierarchyForRootObject {
    // 从 keyWindow 开始遍历
    UIWindow *keyWindow = [SAVisualizedUtils currentValidKeyWindow];
    if (!keyWindow) {
        return @{};
    }

    return [_visualizedSerializer serializedObjectsWithRootObject:keyWindow];
}

@end
