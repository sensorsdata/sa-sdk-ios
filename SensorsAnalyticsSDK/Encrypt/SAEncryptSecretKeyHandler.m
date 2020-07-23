//
// SAEncryptSecretKeyHandler.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/6/18.
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

#import "SAEncryptSecretKeyHandler.h"
#import "SAConfigOptions.h"
#import "SAFileStore.h"
#import "SALog.h"
#import "SAURLUtils.h"
#import "SAValidator.h"
#import "SAAlertController.h"

static NSString * const SAEncryptSecretKey = @"SAEncryptSecretKey";

@interface SAEncryptSecretKeyHandler ()

/// SDK初始化时的 ConfigOptions
@property (nonatomic, copy) SAConfigOptions *configOptions;

@end

@implementation SAEncryptSecretKeyHandler

- (instancetype)initWithConfigOptions:(SAConfigOptions *)configOptions {
    self = [super init];
    if (self) {
        self.configOptions = configOptions;
    }
    return self;
}

- (void)saveSecretKey:(SASecretKey *)secretKey {
    if (!secretKey) {
        return;
    }
    
    if (self.configOptions.saveSecretKey) {
        // 通过用户的回调保存公钥
        self.configOptions.saveSecretKey(secretKey);
        
        [SAFileStore archiveWithFileName:SAEncryptSecretKey value:nil];
        
        SALogDebug(@"Save secret key by saveSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    } else {
        // 存储到本地
        NSData *secretKeyData = [NSKeyedArchiver archivedDataWithRootObject:secretKey];
        [SAFileStore archiveWithFileName:SAEncryptSecretKey value:secretKeyData];
        
        SALogDebug(@"Save secret key by localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    }
}

- (SASecretKey *)loadSecretKey {
    SASecretKey *secretKey = nil;
    
    if (self.configOptions.loadSecretKey) {
        // 通过用户的回调获取公钥
        secretKey = self.configOptions.loadSecretKey();
        
        if (secretKey) {
            SALogDebug(@"Load secret key from loadSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from loadSecretKey callback failed!");
        }
    } else {
        // 通过本地获取公钥
        id secretKeyData = [SAFileStore unarchiveWithFileName:SAEncryptSecretKey];
        secretKey = [NSKeyedUnarchiver unarchiveObjectWithData:secretKeyData];
        
        if (secretKey) {
            SALogDebug(@"Load secret key from localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            SALogDebug(@"Load secret key from localSecretKey failed!");
        }
    }
    
    return secretKey;
}

- (void)checkSecretKeyURL:(NSURL *)url {
    NSString *message = @"当前 App 未开启加密，请开启加密后再试";
    
    if (self.configOptions.enableEncrypt) {
        NSDictionary *paramDic = [SAURLUtils queryItemsWithURL:url];
        NSString *urlVersion = paramDic[@"v"];
        NSString *urlKey = paramDic[@"key"];
        
        if ([SAValidator isValidString:urlVersion] && [SAValidator isValidString:urlKey]) {
            SASecretKey *secretKey = [self loadSecretKey];
            NSString *loadVersion = [@(secretKey.version) stringValue];
            // url 中的 key 为 encode 之后的
            NSString *loadKey = [secretKey.key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
            
            if ([loadVersion isEqualToString:urlVersion] && [loadKey isEqualToString:urlKey]) {
                message = @"密钥验证通过，所选密钥与 App 端密钥相同";
            } else if (![SAValidator isValidString:loadKey]) {
                message = @"密钥验证不通过，App 端密钥为空";
            } else {
                message = [NSString stringWithFormat:@"密钥验证不通过，所选密钥与 App 端密钥不相同。所选密钥版本:%@，App 端密钥版本:%@", urlVersion, loadVersion];
            }
        } else {
            message = @"密钥验证不通过，所选密钥无效";
        }
    }
    
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:nil message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
}

@end
