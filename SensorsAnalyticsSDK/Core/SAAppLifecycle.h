//
// SAAppLifecycle.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2021/4/1.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// SDK 生命周期状态
typedef NS_ENUM(NSUInteger, SAAppLifecycleState) {
    SAAppLifecycleStateInit = 1,
    SAAppLifecycleStateStart,
    SAAppLifecycleStateStartPassively,
    SAAppLifecycleStateEnd,
    SAAppLifecycleStateTerminate,
};

/// 当生命周期状态即将改变时，会发送这个通知
/// object：对象为当前的生命周期对象
/// userInfo：包含 kSAAppLifecycleNewStateKey 和 kSAAppLifecycleOldStateKey 两个 key，分别对应状态改变的前后状态
extern NSNotificationName const kSAAppLifecycleStateWillChangeNotification;
/// 当生命周期状态改变后，会发送这个通知
/// object：对象为当前的生命周期对象
/// userInfo：包含 kSAAppLifecycleNewStateKey 和 kSAAppLifecycleOldStateKey 两个 key，分别对应状态改变的前后状态
extern NSNotificationName const kSAAppLifecycleStateDidChangeNotification;
/// 在状态改变通知回调中，获取新状态
extern NSString * const kSAAppLifecycleNewStateKey;
/// 在状态改变通知回调中，获取之前的状态
extern NSString * const kSAAppLifecycleOldStateKey;

@interface SAAppLifecycle : NSObject

@property (nonatomic, assign, readonly) SAAppLifecycleState state;

@end

NS_ASSUME_NONNULL_END
