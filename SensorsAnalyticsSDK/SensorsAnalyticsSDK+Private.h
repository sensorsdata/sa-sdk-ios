//
//  SensorsAnalyticsSDK_priv.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/8/9.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/**
 埋点方式

 - SensorsAnalyticsTrackTypeCode: 代码埋点
 - SensorsAnalyticsTrackTypeAuto: SDK埋点
 */
typedef NS_ENUM(NSInteger, SensorsAnalyticsTrackType) {
    SensorsAnalyticsTrackTypeCode,
    SensorsAnalyticsTrackTypeAuto,
};

@interface SensorsAnalyticsSDK(Private)
- (void)autoTrackViewScreen:(UIViewController *)viewController;

/**
 调用 track 接口

 @param event 事件名称
 @param trackType track 类型
 */
- (void)track:(NSString *)event withTrackType:(SensorsAnalyticsTrackType)trackType;


/**
 调用 track 接口

 @param event 事件名称
 @param propertieDict event的属性
 * @discussion
 * propertyDict 是一个 Map。
 * 其中的 key 是 Property 的名称，必须是 NSString
 * value 则是 Property 的内容，只支持 NSString、NSNumber、NSSet、NSArray、NSDate 这些类型
 * 特别的，NSSet 或者 NSArray 类型的 value 中目前只支持其中的元素是 NSString
 @param trackType trackType track 类型
 */
- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict withTrackType:(SensorsAnalyticsTrackType)trackType;
@end

#endif /* SensorsAnalyticsSDK_priv_h */
