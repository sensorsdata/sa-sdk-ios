//
// SACommonUtility.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2018/7/26.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

@interface SACommonUtility : NSObject

///按字节截取指定长度字符，包括汉字和表情
+ (NSString *)subByteString:(NSString *)string byteLength:(NSInteger )length;

/// 主线程执行
+ (void)performBlockOnMainThread:(DISPATCH_NOESCAPE dispatch_block_t)block;

/// 获取当前的 UserAgent
+ (NSString *)currentUserAgent;

/// 保存 UserAgent
+ (void)saveUserAgent:(NSString *)userAgent;

/// 计算 hash
+ (NSString *)hashStringWithData:(NSData *)data;
@end
