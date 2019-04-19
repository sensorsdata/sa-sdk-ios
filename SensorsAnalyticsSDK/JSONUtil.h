//
//  JSONUtil.h
//  SensorsAnalyticsSDK
//
//  Created by 曹犟 on 15/7/7.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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

@interface JSONUtil : NSObject

/**
 *  @abstract
 *  把一个Object转成Json字符串
 *
 *  @param obj 要转化的对象Object
 *
 *  @return 转化后得到的字符串
 */
- (NSData *)JSONSerializeObject:(id)obj;

/**
 *  初始化
 *
 *  @return 初始化后的对象
 */
- (id) init;

@end
