//
//  SAJSONUtil.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
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

@interface SAJSONUtil : NSObject

/// 把一个 Object 序列化成 jsonData
/// @param obj 要转化的对象 Object
///  @return 序列化后的 jsonData
+ (NSData *)dataWithJSONObject:(id)obj;


/// 把一个 Object 序列化成 jsonString
/// @param obj 要转化的对象 Object
///  @return 序列化后的 jsonString
+ (NSString *)stringWithJSONObject:(id)obj;

/// jsonData 数据解析
/// @param data 需要解析的 jsonData
///  @return 解析后的对象 Object
+ (id)JSONObjectWithData:(NSData *)data;

/// jsonString 数据解析
/// @param string 需要解析的 jsonString
///  @return 解析后的对象 Object
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
