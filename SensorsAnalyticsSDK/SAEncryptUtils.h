//
//  SAEncryptUtils.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/31.
//  Copyright © 2018 Sensors Data Inc. All rights reserved.
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

NS_ASSUME_NONNULL_BEGIN

@interface SAEncryptUtils : NSObject

/**
 RSA 公钥加密

 @param data 待加密数据
 @param pubKey 公钥
 @return 加密后数据
 */
+ (nullable NSData *)RSAEncryptData:(NSData *)data publicKey:(NSString *)pubKey;

#pragma mark - AES

/**
 随机生成 16 字节秘钥
 @return 秘钥 Byte 数据
 */
+ (NSData *)random16ByteData;

/**
 AES 128 加密

 @param data 待加密数据
 @param keyData 秘钥
 @return 加密并 base64 字符
 */
+ (nullable NSString *)AES128EncryptData:(NSData *)data AESKey:(NSData *)keyData;

@end

NS_ASSUME_NONNULL_END

