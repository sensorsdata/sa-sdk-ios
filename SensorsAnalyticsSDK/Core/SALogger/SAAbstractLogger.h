//
// SAAbstractLogger.h
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SALogMessage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SALogger <NSObject>

@required
- (void)logMessage:(SALogMessage *)logMessage;

@end


@protocol SALogMessageFormatter <NSObject>

@required
- (NSString *)formattedLogMessage:(SALogMessage *)logMessage;

@end

@interface SAAbstractLogger : NSObject <SALogger>

@property (nonatomic, strong) dispatch_queue_t loggerQueue;

@end

NS_ASSUME_NONNULL_END
