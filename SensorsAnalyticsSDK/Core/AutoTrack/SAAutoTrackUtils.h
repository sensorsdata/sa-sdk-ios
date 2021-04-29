//
//  SAAutoTrackUtils.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/22.
//  Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
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
#import "SAAutoTrackProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAAutoTrackUtils : NSObject

#if UIKIT_DEFINE_AS_PROPERTIES
/// 返回当前的 ViewController
@property(class, nonatomic, readonly) UIViewController *currentViewController;
#else
+ (UIViewController *)currentViewController;
#endif

/**
 获取响应链中的下一个 UIViewController

 @param responder 响应链中的对象
 @return 下一个 ViewController
 */
+ (nullable UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder;

///  在间隔时间内是否采集 $AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<SAAutoTrackViewProperty>)object;

/// 判断是否为 RN 元素
+ (BOOL)isKindOfRNView:(UIView *)view;
@end

#pragma mark -
@interface SAAutoTrackUtils (Property)

/**
 通过响应链找到 对象的序号

 -2：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
 -1：同级只存在一个同类元素，兼容 $element_selector 逻辑
 >=0：元素序号

 @param responder 响应链中的对象，可以是 UIView 或者 UIViewController
 @return 序号
 */
+ (NSInteger )itemIndexForResponder:(UIResponder *)responder;

/**
 采集 ViewController 中的事件属性

 @param viewController 需要采集的 ViewController
 @return 事件中与 ViewController 相关的属性字典
 */
+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithViewController:(UIViewController<SAAutoTrackViewControllerProperty> *)viewController;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param isCodeTrack 是否代码埋点采集
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object isCodeTrack:(BOOL)isCodeTrack;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param viewController 控件所在的 ViewController，当为 nil 时，自动采集当前界面上的 ViewController
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<SAAutoTrackViewProperty>)object viewController:(nullable UIViewController<SAAutoTrackViewControllerProperty> *)viewController;

@end

#pragma mark -
@interface SAAutoTrackUtils (IndexPath)

+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath;

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView selectedAtIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
