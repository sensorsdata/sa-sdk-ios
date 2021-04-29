//
// SAVisualizedDebugLogger.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/4/2.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAVisualizedLogger.h"

/// 日志过滤前缀
static NSString * const kSAVisualizedLoggerPrefix = @"SAVisualizedDebugLoggerPrefix:";

/// 日志的 title 和 messsage 分隔符
static NSString * const kSAVisualizedLoggerSeparatedChar = @"：";

@implementation SALoggerVisualizedFormatter

- (NSString *)formattedLogMessage:(SALogMessage *)logMessage {
    return logMessage.message;
}
@end


@implementation SAVisualizedLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        self.loggerQueue = dispatch_queue_create("cn.sensorsdata.SAVisualizedLoggerSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark logMessage
- (void)logMessage:(SALogMessage *)logMessage {
    [super logMessage:logMessage];

    SALoggerVisualizedFormatter *formatter = [[SALoggerVisualizedFormatter alloc] init];

    // 获取日志
    NSString *message = [formatter formattedLogMessage:logMessage];

    // 筛选自定义属性日志
    if (![message containsString:kSAVisualizedLoggerPrefix]) {
        return;
    }
    NSRange range = [message rangeOfString:kSAVisualizedLoggerPrefix];

    NSString *debugLog = [message substringFromIndex:range.location + range.length];

    // 格式校验
    if (![debugLog containsString:kSAVisualizedLoggerSeparatedChar]) {
        return;
    }

    NSRange separatedRange = [debugLog rangeOfString:kSAVisualizedLoggerSeparatedChar];
    NSString *loggerTitle = [debugLog substringToIndex:separatedRange.location];
    NSString *loggerMessage = [debugLog substringFromIndex:separatedRange.location + separatedRange.length];
    if (!loggerTitle || !loggerMessage) {
        return;
    }
    NSDictionary *messageDic = @{@"title": loggerTitle, @"message":loggerMessage};
    // 日志信息
    if (self.delegate && [self.delegate respondsToSelector:@selector(loggerMessage:)]) {
        [self.delegate loggerMessage:messageDic];
    }
}

@end

#pragma mark -
@implementation SAVisualizedLogger (Build)

+ (NSString *)buildLoggerMessageWithTitle:(NSString *)title message:(NSString *)message {
    NSMutableString *logMessage = [NSMutableString stringWithString:kSAVisualizedLoggerPrefix];
    if (title) { // 拼接标题
        [logMessage appendString:title];
        [logMessage appendString:kSAVisualizedLoggerSeparatedChar];
    }
    if (message) { // 拼接内容
        [logMessage appendString:message];
    }
    return [logMessage copy];
}

@end
