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

/// 是否为弹框
+ (BOOL)isAlertForResponder:(UIResponder *)responder;

/// 是否为弹框点击
+ (BOOL)isAlertClickForView:(UIView *)view;

///  在间隔时间内是否采集 $AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<SAAutoTrackViewProperty>)object;

/// 判断是否为 RN 元素
+ (BOOL)isKindOfRNView:(UIView *)view;
@end

#pragma mark -
@interface SAAutoTrackUtils (Property)

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
@interface SAAutoTrackUtils (ViewPath)

/**
 自动采集时，是否忽略这个 viewController 对象

 @param viewController 需要判断的对象
 @return 是否忽略
 */
+ (BOOL)isIgnoredViewPathForViewController:(UIViewController *)viewController;

/**
 创建 view 的唯一标识符

 @param view 需要创建的对象
 @return 唯一标识符
 */
+ (nullable NSString *)viewIdentifierForView:(UIView *)view;

/**
通过响应链找到 对象的点击图路径

@param responder 响应链中的对象，可以是 UIView 或者 UIViewController
@return 路径
*/
+ (NSString *)itemHeatMapPathForResponder:(UIResponder *)responder;

/**
 通过响应链找到 对象的序号

 @param responder 响应链中的对象，可以是 UIView 或者 UIViewController
 @return 路径
 */
+ (NSInteger )itemIndexForResponder:(UIResponder *)responder;

/**
 找到 view 的路径数组

 @param view 需要获取路径的 view
 @return 路径数组
 */
+ (NSArray<NSString *> *)viewPathsForView:(UIView *)view;

/**
 获取 view 的路径字符串

 @param view 需要获取路径的 view
 @param viewController view 所在的 viewController
 @return 路径字符串
 */
+ (nullable NSString *)viewPathForView:(UIView *)view atViewController:(UIViewController *)viewController;

/**
获取 view 的模糊路径

@param view 需要获取路径的 view
@param viewController view 所在的 viewController
@param shouldSimilarPath 是否需要取相似路径
@return 路径字符串
*/
+ (NSString *)viewSimilarPathForView:(UIView *)view atViewController:(UIViewController *)viewController shouldSimilarPath:(BOOL)shouldSimilarPath;
@end

#pragma mark -
@interface SAAutoTrackUtils (IndexPath)

+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
