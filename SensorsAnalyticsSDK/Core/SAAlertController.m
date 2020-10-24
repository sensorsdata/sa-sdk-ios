//
//  SAAlertController.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2019/3/4.
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

#import "SAAlertController.h"

#pragma mark - SAAlertAction
@interface SAAlertAction ()
@property (nonatomic) NSInteger tag;
@end
@implementation SAAlertAction

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(SAAlertActionStyle)style handler:(void (^ __nullable)(SAAlertAction *))handler {
    SAAlertAction *action = [[SAAlertAction alloc] init];
    action.title = title;
    action.style = style;
    action.handler = handler;
    return action;
}

@end

#pragma mark - SAAlertController
@interface SAAlertController () <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIWindow *alertWindow;

@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic) SAAlertControllerStyle preferredStyle;

@property (nonatomic, strong) NSMutableArray<SAAlertAction *> *actions;

@end

@implementation SAAlertController

- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(SAAlertControllerStyle)preferredStyle {
    self = [super init];
    if (self) {
        _alertTitle = title;
        _alertMessage = message;
        _preferredStyle = preferredStyle;
        _actions = [NSMutableArray arrayWithCapacity:4];
        
        if (NSClassFromString(@"UIAlertController")) {
            UIWindow *alertWindow = [self currentAlertWindow];
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            alertWindow.rootViewController = self;
            alertWindow.hidden = NO;
            _alertWindow = alertWindow;
        } else {
            _alertWindow = [UIApplication sharedApplication].keyWindow;
        }
    }
    return self;
}

- (void)addActionWithTitle:(NSString *)title style:(SAAlertActionStyle)style handler:(void (^ __nullable)(SAAlertAction *))handler {
    SAAlertAction *action = [SAAlertAction actionWithTitle:title style:style handler:handler];
    [self.actions addObject:action];
}

- (void)show {
    if (NSClassFromString(@"UIAlertController")) {
        [self showAlertController];
    } else if (self.preferredStyle == SAAlertControllerStyleAlert) {
        [self showAlertView];
    } else if (self.preferredStyle == SAAlertControllerStyleActionSheet) {
        [self showActionSheet];
    }
}

- (void)showAlertController {
    if (@available(iOS 8.0, *)) {
        UIAlertControllerStyle style = self.preferredStyle == SAAlertControllerStyleAlert ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.alertTitle message:self.alertMessage preferredStyle:style];

        for (SAAlertAction *action in self.actions) {
            UIAlertActionStyle style = UIAlertActionStyleDefault;
            switch (action.style) {
                case SAAlertActionStyleCancel:
                    style = UIAlertActionStyleCancel;
                    break;
                case SAAlertActionStyleDestructive:
                    style = UIAlertActionStyleDestructive;
                    break;
                default:
                    style = UIAlertActionStyleDefault;
                    break;
            }
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:action.title style:style handler:^(UIAlertAction *alertAction) {
                if (action.handler) {
                    action.handler(action);
                }
                self.alertWindow.hidden = YES;
                self.alertWindow = nil;
            }];
            [alertController addAction:alertAction];
        }
        [self.actions removeAllObjects];

        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)showAlertView {
    // 让系统持有这个 ViewController
    self.view.frame = CGRectZero;
    [self.alertWindow.rootViewController.view addSubview:self.view];
    [self.alertWindow.rootViewController addChildViewController:self];
    
    __block NSString *cancelButtonTitle = nil;
    __block NSString *otherButtonTitle1 = nil;
    __block NSString *otherButtonTitle2 = nil;
    __block NSString *otherButtonTitle3 = nil;
    __block NSString *otherButtonTitle4 = nil;
    [self.actions enumerateObjectsUsingBlock:^(SAAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 4) {
            *stop = YES;
            return;
        }
        if (obj.style == SAAlertActionStyleCancel || obj.style == SAAlertActionStyleDestructive) {
            cancelButtonTitle = obj.title;
            obj.tag = 0;
        } else if (!otherButtonTitle1) {
            otherButtonTitle1 = obj.title;
            obj.tag = 1;
        }  else if (!otherButtonTitle2) {
            otherButtonTitle2 = obj.title;
            obj.tag = 2;
        }  else if (!otherButtonTitle3) {
            otherButtonTitle3 = obj.title;
            obj.tag = 3;
        }  else if (!otherButtonTitle4) {
            otherButtonTitle4 = obj.title;
            obj.tag = 4;
        }
    }];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle message:self.alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle1, otherButtonTitle2, otherButtonTitle3, otherButtonTitle4, nil];
    [alertView show];
}

- (void)showActionSheet {
    // 让系统持有这个 ViewController
    self.view.frame = CGRectZero;
    [self.alertWindow.rootViewController.view addSubview:self.view];
    [self.alertWindow.rootViewController addChildViewController:self];
    
    NSString *cancelButtonTitle = nil;
    NSString *destructiveButtonTitle = nil;
    __block NSString *otherButtonTitle1 = nil;
    __block NSString *otherButtonTitle2 = nil;
    __block NSString *otherButtonTitle3 = nil;
    __block NSString *otherButtonTitle4 = nil;
    
    NSInteger startTag = 0;
    for (SAAlertAction *obj in self.actions) {
        if (obj.style == SAAlertActionStyleCancel) {
            cancelButtonTitle = obj.title;
            obj.tag = self.actions.count - 1;
        }
        if (obj.style == SAAlertActionStyleDestructive) {
            destructiveButtonTitle = obj.title;
            obj.tag = 0;
            startTag = 1;
        }
    }
    [self.actions enumerateObjectsUsingBlock:^(SAAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.style == SAAlertActionStyleCancel || obj.style == SAAlertActionStyleDestructive) {
            return;
        }
        if (!otherButtonTitle1) {
            otherButtonTitle1 = obj.title;
            obj.tag = startTag;
        }  else if (!otherButtonTitle2) {
            otherButtonTitle2 = obj.title;
            obj.tag = startTag + 1;
        }  else if (!otherButtonTitle3) {
            otherButtonTitle3 = obj.title;
            obj.tag = startTag + 2;
        }  else if (!otherButtonTitle4) {
            otherButtonTitle4 = obj.title;
            obj.tag = startTag + 3;
        }
    }];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:self.alertTitle delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitle1, otherButtonTitle2, otherButtonTitle3, otherButtonTitle4, nil];
    [sheet showInView:self.alertWindow];
}

- (UIWindow *)currentAlertWindow {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        if (scene) {
            return [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
#endif
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    for (SAAlertAction *action in self.actions) {
        if (action.tag == buttonIndex && action.handler) {
            action.handler(action);
            break;
        }
    }
    [self.actions removeAllObjects];
    self.actions = nil;
    
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    for (SAAlertAction *action in self.actions) {
        if (action.tag == buttonIndex && action.handler) {
            action.handler(action);
            break;
        }
    }
    [self.actions removeAllObjects];
    self.actions = nil;
    
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end
