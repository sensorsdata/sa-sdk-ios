//
// SASecretKeyFactory.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/20.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import <Foundation/Foundation.h>

@class SASecretKey;

NS_ASSUME_NONNULL_BEGIN

@interface SASecretKeyFactory : NSObject

typedef BOOL(^EncryptorChecker)(SASecretKey *secretKey);

/// {  "key_v2": { "pkv": 27, "public_key": "<公钥>", "type": "SM2+SM4"} ,
///  "key ": { " pkv": 23, "public_key": "<公钥>", "key_ec":  "{ \"pkv\":26,\"type\":\"EC\",\"public_key\":\<公钥>\" }" } }

/// 根据 key_v2 秘钥信息生成对应的秘钥实例对象，加密插件化 2.0 逻辑
/// @param version2 key_v2 秘钥信息
/// @return 返回可用秘钥对象
+ (SASecretKey *)createSecretKeyByVersion2:(NSDictionary *)version2;

/// 根据 key 秘钥信息生成对应的秘钥实例对象，加密插件化 1.0 逻辑
/// @param version1 key 版本秘钥信息
/// @return 返回可用秘钥对象
+ (SASecretKey *)createSecretKeyByVersion1:(NSDictionary *)version1;

@end

NS_ASSUME_NONNULL_END
