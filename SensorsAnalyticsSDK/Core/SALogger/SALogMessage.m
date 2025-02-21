//
// SALogMessage.m
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SALogMessage.h"

@implementation SALogMessage

- (instancetype)initWithMessage:(NSString *)message level:(SALogLevel)level file:(NSString *)file function:(NSString *)function line:(NSUInteger)line context:(NSInteger)context timestamp:(NSDate *)timestamp {
    if (self = [super init]) {
        _message = message;
        _level = level;
        _file = file;
        _function = function;
        _line = line;
        _context = context;
        _timestamp = timestamp;
        _fileName = file.lastPathComponent;
    }
    return self;
}

@end
