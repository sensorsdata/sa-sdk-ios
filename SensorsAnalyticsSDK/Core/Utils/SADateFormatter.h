//
// SADateFormatter.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2019/12/23.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSAEventDateFormatter;

@interface SADateFormatter : NSObject

/**
*  @abstract
*  获取 NSDateFormatter 单例对象
*
*  @param string 日期格式
*
*  @return 返回 NSDateFormatter 单例对象
*/
+ (NSDateFormatter *)dateFormatterFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
