//
// SAConfigOptions+Encrypt.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAEncryptProtocol.h"
#import "SAConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAConfigOptions (Encrypt)

/// 是否开启加密
@property (nonatomic, assign) BOOL enableEncrypt API_UNAVAILABLE(macos);

- (void)registerEncryptor:(id<SAEncryptProtocol>)encryptor API_UNAVAILABLE(macos);

/// 存储公钥的回调。务必保存秘钥所有字段信息
@property (nonatomic, copy) void (^saveSecretKey)(SASecretKey * _Nonnull secretKey) API_UNAVAILABLE(macos);

/// 获取公钥的回调。务必回传秘钥所有字段信息
@property (nonatomic, copy) SASecretKey * _Nonnull (^loadSecretKey)(void) API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
