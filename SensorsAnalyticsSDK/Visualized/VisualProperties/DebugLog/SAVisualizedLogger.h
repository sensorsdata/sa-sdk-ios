//
// SAVisualizedLogger.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/4/2.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAAbstractLogger.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SAVisualizedLoggerDelegate <NSObject>

- (void)loggerMessage:(NSDictionary *)messageDic;

@end

@interface SALoggerVisualizedFormatter : NSObject <SALogMessageFormatter>

@end


/// 自定义属性日志打印
@interface SAVisualizedLogger : SAAbstractLogger

@property (weak, nonatomic, nullable) id<SAVisualizedLoggerDelegate> delegate;

@end

#pragma mark -
@interface SAVisualizedLogger(Build)

/// 构建 log 日志
/// @param title 日志标题
/// @param format 日志详情拼接
+ (NSString *)buildLoggerMessageWithTitle:(NSString *)title message:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
