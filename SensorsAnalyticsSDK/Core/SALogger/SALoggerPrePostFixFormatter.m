//
// SALoggerPrePostFixFormatter.m
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SALoggerPrePostFixFormatter.h"
#import "SALogMessage.h"

@implementation SALoggerPrePostFixFormatter

- (NSString *)formattedLogMessage:(nonnull SALogMessage *)logMessage {
    return [NSString stringWithFormat:@"%@ %@ %@", self.prefix, logMessage.message, self.postfix];
}

@end
