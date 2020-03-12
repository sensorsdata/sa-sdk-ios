//
//  SANetwork+URLUtils.h
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/4/18.
///  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SANetwork.h"

@interface SANetwork (URLUtils)

+ (NSString *)hostWithURL:(NSURL *)url;
+ (NSString *)hostWithURLString:(NSString *)URLString;

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url;
+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString;

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params;

/// 解码并解析 URL 参数
/// @param url url 对象
+ (NSDictionary<NSString *, NSString *> *)decodeRueryItemsWithURL:(NSURL *)url;
@end
