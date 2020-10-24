//
// SAFileStore.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/1/6.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAFileStore : NSObject

/**
 @abstract
 文件本地存储

 @param fileName 本地存储文件名
 @param value 本地存储文件内容

 @return 存储结果
*/
+ (BOOL)archiveWithFileName:(NSString *)fileName value:(nullable id)value;

/**
 @abstract
 获取本地存储的文件内容

 @param fileName 本地存储文件名
 @return 本地存储文件内容
*/
+ (nullable id)unarchiveWithFileName:(NSString *)fileName;

/**
 @abstract
 获取文件路径

 @param fileName 文件名
 @return 文件全路径
*/
+ (NSString *)filePath:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
