//
// SAAlertController.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/3/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#if TARGET_OS_IOS

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

        UIWindow *alertWindow = [self currentAlertWindow];
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.rootViewController = self;
        alertWindow.hidden = NO;
        _alertWindow = alertWindow;
    }
    return self;
}

- (void)addActionWithTitle:(NSString *)title style:(SAAlertActionStyle)style handler:(void (^ __nullable)(SAAlertAction *))handler {
    SAAlertAction *action = [SAAlertAction actionWithTitle:title style:style handler:handler];
    [self.actions addObject:action];
}

- (void)show {
    [self showAlertController];
}

- (void)showAlertController {
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

- (UIWindow *)currentAlertWindow NS_EXTENSION_UNAVAILABLE("App Alert not supported for iOS extensions.") {
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

@end

#endif
