//
// SADataEncryptBuilder.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2019/7/23.
// Copyright © 2019-2020 Sensors Data Co., Ltd. All rights reserved.
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


#import "SADataEncryptBuilder.h"
#import "SAEncryptUtils.h"
#import "SAGzipUtility.h"
#import "SAJSONUtil.h"

@interface SADataEncryptBuilder()

@property(nonatomic,strong) SAJSONUtil *jsonUtil;
/// RSA 公钥配置
@property(nonatomic, strong) SASecretKey *rsaSecretKey;

///AES 秘钥
@property(nonatomic, copy) NSData *aesSecretDataKey;
/// RSA 加密后 AES 秘钥
@property(nonatomic, copy) NSString *rsaEncryptAESKey;
@end


@implementation SADataEncryptBuilder

#pragma mark - initializ
- (instancetype)initWithRSAPublicKey:(SASecretKey *)secretKey {
    self = [super init];
    if (self) {
        _jsonUtil = [[SAJSONUtil alloc] init];
        [self updateRSAPublicSecretKey:secretKey];
    }
    return self;
}

- (void)updateRSAPublicSecretKey:(nonnull SASecretKey *)secretKey {
    if (secretKey.key.length > 0 && ![secretKey.key isEqualToString:self.rsaSecretKey.key]) {
        self.rsaSecretKey = secretKey;
        
        //对秘钥 RSA 加密
        NSData *rsaEncryptData = [SAEncryptUtils RSAEncryptData:self.aesSecretDataKey publicKey:self.rsaSecretKey.key];
        self.rsaEncryptAESKey = [rsaEncryptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
}

-(NSData *)aesSecretDataKey {
    if (!_aesSecretDataKey) {
        _aesSecretDataKey = [SAEncryptUtils random16ByteData];
    }
    return _aesSecretDataKey;
}

- (NSString *)rsaEncryptAESKey {
    if (!_rsaEncryptAESKey && self.rsaSecretKey.key.length > 0) {
        //对秘钥 RSA 加密
        NSData *rsaEncryptData = [SAEncryptUtils RSAEncryptData:self.aesSecretDataKey publicKey:self.rsaSecretKey.key];
        _rsaEncryptAESKey = [rsaEncryptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    return _rsaEncryptAESKey;
}

- (nullable NSDictionary *)encryptionJSONObject:(id)obj {
    if (!self.rsaSecretKey || !self.rsaEncryptAESKey) {
        return nil;
    }

    NSData *jsonData = [self.jsonUtil JSONSerializeObject:obj];
    NSString *encodingString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *encodingData = [encodingString dataUsingEncoding:NSUTF8StringEncoding];
    //使用 gzip 进行压缩
    NSData *zippedData = [SAGzipUtility gzipData:encodingData];

    //AES128 加密
    NSString *encryptString = [SAEncryptUtils AES128EncryptData:zippedData AESKey:self.aesSecretDataKey];
    if (!encryptString) {
        return nil;
    }
    //封装加密的数据结构
    NSMutableDictionary *secretObj = [NSMutableDictionary dictionary];
    secretObj[@"pkv"] = @(self.rsaSecretKey.version);
    secretObj[@"ekey"] = self.rsaEncryptAESKey;
    secretObj[@"payload"] = encryptString;
    return secretObj;
}

- (nullable NSArray *)buildFlushEncryptionDataWithRecords:(NSArray *)recordArray {
    /***** 构造加密数据结构 *****/
    // 字典，方便去重
    NSMutableDictionary <NSString *,NSMutableArray *> *ekeyPayloadsDic = [NSMutableDictionary dictionary];
    
    for (NSString *json in recordArray) {
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        if (jsonDic && [jsonDic.allKeys containsObject:@"ekey"]) {
            
            NSMutableArray *sameEncryptArray = ekeyPayloadsDic[jsonDic[@"ekey"]];
            if (sameEncryptArray.count == 0) {
                sameEncryptArray = [NSMutableArray array];
                [sameEncryptArray addObject:[jsonDic mutableCopy]];
                [ekeyPayloadsDic setObject:sameEncryptArray forKey:jsonDic[@"ekey"]];
            } else {
                [sameEncryptArray addObject:[jsonDic mutableCopy]];
            }
        }
    }
    
    NSMutableArray *encryptArray = [NSMutableArray array];
    for (NSString *ekey in ekeyPayloadsDic.allKeys) {
        NSMutableArray *sameEncryptArray = ekeyPayloadsDic[ekey];
        NSMutableDictionary *encryptDic = [NSMutableDictionary dictionaryWithDictionary:sameEncryptArray.firstObject];
        [encryptDic removeObjectForKey:@"payload"];
        NSMutableArray *sameEncryptPayloads = [NSMutableArray array];
        for (NSDictionary *dic in sameEncryptArray) {
            [sameEncryptPayloads addObject:dic[@"payload"]];
        }
        encryptDic[@"payloads"] = sameEncryptPayloads;
        
        NSData *encrypData = [self.jsonUtil JSONSerializeObject:encryptDic];
        NSString *encrypString = [[NSString alloc] initWithData:encrypData encoding:NSUTF8StringEncoding];
        [encryptArray addObject:encrypString];
    }
    
    if (encryptArray.count > 0) {
        NSArray *contentArray = [NSArray arrayWithArray:encryptArray];
        return contentArray;
    } else {
        return nil;
    }
}

@end
