//
// SAChannelMatchManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/8/29.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAConfigOptions.h"
#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (ChannelMatchPrivate)

@property (nonatomic, assign) BOOL enableChannelMatch;

@end

@interface SAChannelMatchManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SAChannelMatchModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;

/// 是否采集过激活事件
/// @param disableCallback 根据 disableCallback 获取本地标记 key 值
- (BOOL)isTrackedAppInstallWithDisableCallback:(BOOL)disableCallback;

/// 设置已经采集激活事件标记
/// @param disableCallback 根据 disableCallback 获取本地标记 key 值
- (void)setTrackedAppInstallWithDisableCallback:(BOOL)disableCallback;

/**
 * @abstract
 * 用于在 App 首次启动时追踪渠道来源，并设置追踪渠道事件的属性。SDK 会将渠道值填入事件属性 $utm_ 开头的一系列属性中。
 *
 * @param event  event 的名称
 * @param properties     event 的属性
 * @param disableCallback     是否关闭这次渠道匹配的回调请求
*/
- (void)trackAppInstall:(NSString *)event properties:(nullable NSDictionary *)properties disableCallback:(BOOL)disableCallback;

/// 调用 track 接口并附加渠道信息
///
/// 注意：这个方法需要在 serialQueue 中调用，保证线程安全
///
/// @param obj 事件对象
/// @param properties 事件属性
- (void)trackChannelWithEventObject:(SABaseEventObject *)obj properties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
