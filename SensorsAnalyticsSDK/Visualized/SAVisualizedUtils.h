//
// SAVisualizedUtils.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/3/3.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 可视化相关工具类
@interface SAVisualizedUtils : NSObject

/// view 是否被覆盖
+ (BOOL)isCoveredForView:(UIView *)view;

/// view 是否可见
+ (BOOL)isVisibleForView:(UIView *)view;

/// 解析构造 web 元素
+ (NSArray *)analysisWebElementWithWebView:(WKWebView *)webView;

///  获取 RN 当前页面信息
+ (NSDictionary <NSString *, NSString *>*)currentRNScreenVisualizeProperties;

/// 是否为 RN 内的原生页面
+ (BOOL)isRNCustomViewController:(UIViewController *)viewController;

/// 获取当前有效的 keyWindow
+ (UIWindow *)currentValidKeyWindow;

/// 是否可触发 AppClick 全埋点
/// @param control 当前元素
+ (BOOL)isAutoTrackAppClickWithControl:(UIControl *)control;

/// 是否忽略子元素遍历
/// @param view 当前视图
+ (BOOL)isIgnoreSubviewsWithView:(UIView *)view;


/// view 截图
/// @param view 需要截图的 view
+ (UIImage *)screenshotWithView:(UIView *)view;
@end

#pragma mark -
@interface SAVisualizedUtils (ViewPath)

/**
 自动采集时，是否忽略这个 viewController 对象

 @param viewController 需要判断的对象
 @return 是否忽略
 */
+ (BOOL)isIgnoredViewPathForViewController:(UIViewController *)viewController;

/**
 是否忽略当前元素相对路径

 @param view 当前元素
 @return 是否忽略
 */
+ (BOOL)isIgnoredItemPathWithView:(UIView *)view;

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

/// 当前 view 所在同类页面序号
+ (NSInteger)pageIndexWithView:(UIView *)view;

/**
 当前同类页面序号
 -1：同级只存在一个同类页面，不需要用比较 pageIndex
 >=0：同级同类页面序号序号

 @param viewController 当前页面
 @return 序号
 */
+ (NSInteger)pageIndexWithViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
