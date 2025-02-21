//
// SALoggerPrePostFixFormatter.h
// Logger
//
// Created by 陈玉国 on 2019/12/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SALog+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SALoggerPrePostFixFormatter : NSObject <SALogMessageFormatter>

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *postfix;

@end

NS_ASSUME_NONNULL_END
