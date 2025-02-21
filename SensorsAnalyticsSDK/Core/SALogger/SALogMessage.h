//
// SALogMessage.h
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SALog.h"

NS_ASSUME_NONNULL_BEGIN

@interface SALogMessage : NSObject

@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, assign, readonly) SALogLevel level;
@property (nonatomic, copy, readonly) NSString *file;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, copy, readonly) NSString *function;
@property (nonatomic, assign, readonly) NSUInteger line;
@property (nonatomic, assign, readonly) NSInteger context;
@property (nonatomic, strong, readonly) NSDate *timestamp;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithMessage:(NSString *)message
                          level:(SALogLevel)level
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSUInteger)line
                        context:(NSInteger)context
                      timestamp:(NSDate *)timestamp NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
