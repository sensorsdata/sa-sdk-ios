//
// SAReadWriteLock.h
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/5/21.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAReadWriteLock : NSObject

/**
*  @abstract
*  初始化方法
*
*  @param queueLabel 队列的标识
*
*  @return 读写锁实例
*
*/
- (instancetype)initWithQueueLabel:(NSString *)queueLabel NS_DESIGNATED_INITIALIZER; 

/// 禁用 init 初始化
- (instancetype)init NS_UNAVAILABLE;

/// 禁用 new 初始化
+ (instancetype)new NS_UNAVAILABLE;

/**
*  @abstract
*  通过读写锁读取数据
*
*  @param block 读取操作
*
*  @return 读取的数据
*
*/
- (id)readWithBlock:(id(^)(void))block;

/**
*  @abstract
*  通过读写锁写入数据
*
*  @param block 写入操作
*
*/
- (void)writeWithBlock:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
