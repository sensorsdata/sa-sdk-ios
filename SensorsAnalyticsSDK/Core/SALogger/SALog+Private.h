//
// SALog+Private.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2020/3/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAAbstractLogger.h"

@interface SALog (Private)

@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

+ (void)addLogger:(SAAbstractLogger<SALogger> *)logger;
+ (void)addLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers;
+ (void)removeLogger:(SAAbstractLogger<SALogger> *)logger;
+ (void)removeLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers;
+ (void)removeAllLoggers;

- (void)addLogger:(SAAbstractLogger<SALogger> *)logger;
- (void)addLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers;
- (void)removeLogger:(SAAbstractLogger<SALogger> *)logger;
- (void)removeLoggers:(NSArray<SAAbstractLogger<SALogger> *> *)loggers;
- (void)removeAllLoggers;

@end
