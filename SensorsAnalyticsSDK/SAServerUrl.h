//
//  SAServerUrl.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/1/2.
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

@interface SAServerUrl : NSObject
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *host;
@property (nonatomic, copy, readonly) NSString *project;
@property (nonatomic, copy, readonly) NSString *token;

- (instancetype)initWithUrl:(NSString *)url;
- (BOOL)check:(SAServerUrl *)serverUrl;


/**
 解析 URL 的参数

 @param urlComponents URL 的 urlComponents
 @return 参数字典
 */
+ (NSDictionary *)analysisQueryItemWithURLComponent:(NSURLComponents *)urlComponents;


/**
 根据参数拼接 URL Query

 @param params 参数字典
 @return query 字符串
 */
+ (NSString *)collectURLQueryWithParams:(NSDictionary <NSString *, NSString*>*)params;
@end
