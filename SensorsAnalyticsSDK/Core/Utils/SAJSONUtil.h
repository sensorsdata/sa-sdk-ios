//
// SAJSONUtil.h
// SensorsAnalyticsSDK
//
// Created by 曹犟 on 15/7/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAJSONUtil : NSObject

/// 把一个 Object 序列化成 jsonData
/// @param obj 要转化的对象 Object
/// @return 序列化后的 jsonData
+ (NSData *)dataWithJSONObject:(id)obj;


/// 把一个 Object 序列化成 jsonString
/// @param obj 要转化的对象 Object
/// @return 序列化后的 jsonString
+ (NSString *)stringWithJSONObject:(id)obj;

/// jsonData 数据解析
/// @param data 需要解析的 jsonData
/// @return 解析后的对象 Object
+ (id)JSONObjectWithData:(NSData *)data;

/// jsonString 数据解析
/// @param string 需要解析的 jsonString
/// @return 解析后的对象 Object
+ (id)JSONObjectWithString:(NSString *)string;

/// jsonString 数据解析
/// @param string 需要解析的 jsonString
/// @param options NSJSONReadingOptions 配置
/// @return 解析后的对象 Object
+ (id)JSONObjectWithString:(NSString *)string options:(NSJSONReadingOptions)options;

/// jsonData 数据解析
/// @param data 需要解析的 jsonData
/// @param options NSJSONReadingOptions 配置
/// @return 解析后的对象 Object
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)options;

@end
