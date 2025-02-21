//
// SAAlertController.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/3/4.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

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

#if TARGET_OS_IOS
/**
 神策弹框的 SAAlertController，添加到黑名单。
 防止 $AppViewScreen 事件误采
 内部使用 UIAlertController 实现
 */
@interface SAAlertController : UIViewController


/**
 SAAlertController 初始化，⚠️ 注意 ActionSheet 样式不支持 iPad❗️❗️❗️

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

#endif

NS_ASSUME_NONNULL_END
