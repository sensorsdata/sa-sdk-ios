//
// SensorsAnalyticsSDK_priv.h
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#ifndef SensorsAnalyticsSDK_Private_h
#define SensorsAnalyticsSDK_Private_h
#import "SensorsAnalyticsSDK.h"
#import <Foundation/Foundation.h>
#import "SANetwork.h"
#import "SAHTTPSession.h"
#import "SATrackEventObject.h"
#import "SAAppLifecycle.h"


@interface SensorsAnalyticsSDK(Private)

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用 startWithConfigOptions: 。
 * 这个方法与 sharedInstance 类似，但是当远程配置关闭 SDK 时，sharedInstance 方法会返回 nil，这个方法仍然能获取到 SDK 的单例
 *
 * @return 返回的单例
 */
+ (SensorsAnalyticsSDK *)sdkInstance;

+ (NSString *)libVersion;

#pragma mark - method

/// 触发事件
/// @param object 事件对象
/// @param properties 事件属性
- (void)trackEventObject:(SABaseEventObject *)object properties:(NSDictionary *)properties;

/// 准备采集动态公共属性
///
/// 需要在队列外执行
- (void)buildDynamicSuperProperties;

#pragma mark - property
@property (nonatomic, strong, readonly) SAConfigOptions *configOptions;
@property (nonatomic, strong, readonly) SANetwork *network;
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@end

/**
 SAConfigOptions 实现
 私有 property
 */
@interface SAConfigOptions()

/// 数据接收地址 serverURL
@property(atomic, copy) NSString *serverURL;

/// App 启动的 launchOptions
@property(nonatomic, strong) id launchOptions;

@property (nonatomic) SensorsAnalyticsDebugMode debugMode;

@property (nonatomic, strong) NSMutableArray *storePlugins;

//忽略页面浏览时长的页面
@property  (nonatomic, copy) NSSet<Class> *ignoredPageLeaveClasses;

@property (atomic, strong) NSMutableArray<SAPropertyPlugin *> *propertyPlugins;

@end

#endif /* SensorsAnalyticsSDK_priv_h */
