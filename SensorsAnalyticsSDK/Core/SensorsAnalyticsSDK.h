//  SensorsAnalyticsSDK.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/1.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

#import "SensorsAnalyticsSDK+Public.h"
#import "SASecurityPolicy.h"
#import "SAConfigOptions.h"
#import "SAConstants.h"

#if __has_include("SensorsAnalyticsSDK+WKWebView.h")
#import "SensorsAnalyticsSDK+WKWebView.h"
#endif

#if __has_include("SensorsAnalyticsSDK+WebView.h")
#import "SensorsAnalyticsSDK+WebView.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * @abstract
 * 在 DEBUG 模式下，发送错误时会抛出该异常
 */
@interface SensorsAnalyticsDebugException : NSException

@end

@protocol SAUIViewAutoTrackDelegate <NSObject>

//UITableView
@optional
- (NSDictionary *)sensorsAnalytics_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
- (NSDictionary *)sensorsAnalytics_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UIImage (SensorsAnalytics)
@property (nonatomic, copy) NSString* sensorsAnalyticsImageName;
@end

@interface UIView (SensorsAnalytics)
- (nullable UIViewController *)sensorsAnalyticsViewController __attribute__((deprecated("已过时")));

/// viewID
@property (nonatomic, copy) NSString* sensorsAnalyticsViewID;

/// AutoTrack 时，是否忽略该 View
@property (nonatomic, assign) BOOL sensorsAnalyticsIgnoreView;

/// AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic, assign) BOOL sensorsAnalyticsAutoTrackAfterSendAction;

/// AutoTrack 时，View 的扩展属性
@property (nonatomic, strong) NSDictionary* sensorsAnalyticsViewProperties;

@property (nonatomic, weak, nullable) id<SAUIViewAutoTrackDelegate> sensorsAnalyticsDelegate;
@end



/**
 * @abstract
 * 自动追踪 (AutoTrack) 中，实现该 Protocal 的 Controller 对象可以通过接口向自动采集的事件中加入属性
 *
 * @discussion
 * 属性的约束请参考 track:withProperties:
 */
@protocol SAAutoTracker <NSObject>

@required
- (NSDictionary *)getTrackProperties;

@end

@protocol SAScreenAutoTracker <SAAutoTracker>

@required
- (NSString *)getScreenUrl;

@end

NS_ASSUME_NONNULL_END

