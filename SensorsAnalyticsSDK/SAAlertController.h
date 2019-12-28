//
//  SAAlertController.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SAAlertActionStyle) {
    SAAlertActionStyleDefault,
    SAAlertActionStyleCancel,
    SAAlertActionStyleDestructive
};

typedef NS_ENUM(NSUInteger, SAAlertControllerStyle) {
    SAAlertControllerStyleActionSheet = 0,
    SAAlertControllerStyleAlert
};

@interface SAAlertAction : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) SAAlertActionStyle style;
@property (nonatomic, copy) void (^handler)(SAAlertAction *);

@property (nonatomic, readonly) NSInteger tag;

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(SAAlertActionStyle)style handler:(void (^ __nullable)(SAAlertAction *))handler;

@end

/**
 神策弹框的 SAAlertController，添加到黑名单。
 防止 $AppViewScreen 事件误采
 当系统版本低于8.0时，会使用 UIAlertView 或者 UIActionSheet，此时最多支持 4 个其他按钮
 */
@interface SAAlertController : UIViewController


/**
 SAAlertController 初始化

 @param title 标题
 @param message 提示信息
 @param preferredStyle 弹框类型
 @return SAAlertController
 */
- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(SAAlertControllerStyle)preferredStyle;


/**
 添加一个 Action

 @param title Action 显示的 title
 @param style Action 的类型
 @param handler 回调处理方法，带有这个 Action 本身参数
 */
- (void)addActionWithTitle:(NSString *_Nullable)title style:(SAAlertActionStyle)style handler:(void (^ __nullable)(SAAlertAction *))handler;


/**
 显示 SAAlertController
 */
- (void)show;

@end

NS_ASSUME_NONNULL_END
