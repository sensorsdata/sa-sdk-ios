//
// SALoggerConsoleColorFormatter.h
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAbstractLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface SALoggerConsoleFormatter : NSObject <SALogMessageFormatter>

@property (nonatomic, copy) NSString *prefix;

@end

NS_ASSUME_NONNULL_END
