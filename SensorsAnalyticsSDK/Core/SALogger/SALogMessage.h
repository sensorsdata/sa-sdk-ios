//
//  SALogMessage.h
//  Logger
//
//  Created by 陈玉国 on 2019/12/26.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
