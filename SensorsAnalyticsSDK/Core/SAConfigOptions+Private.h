//
// SAConfigOptions+Private.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/4/16.
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

#import "SAEncryptProtocol.h"
#import "SAConfigOptions.h"

@interface SAConfigOptions (Private)

@property (nonatomic, copy, readonly) NSArray *encryptors;

- (void)registerEncryptor:(id<SAEncryptProtocol>)encryptor;

@end

@interface SASecretKey (Private)

/// 对称加密类型
@property(nonatomic, copy) NSString *symmetricEncryptType;

/// 非对称加密类型
@property(nonatomic, copy) NSString *asymmetricEncryptType;

@end
