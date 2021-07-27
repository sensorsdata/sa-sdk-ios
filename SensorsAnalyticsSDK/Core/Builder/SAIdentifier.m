//
// SAIdentifier.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/17.
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

#import "SAIdentifier.h"
#import "SAConstants+Private.h"
#import "SAFileStore.h"
#import "SAValidator.h"
#import "SALog.h"

#if TARGET_OS_IOS
#import "SAKeyChainItemWrapper.h"
#import <UIKit/UIKit.h>
#endif

@interface SAIdentifier ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, copy, readwrite) NSString *loginId;
@property (nonatomic, copy, readwrite) NSString *anonymousId;

@end

@implementation SAIdentifier

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        dispatch_async(_queue, ^{
            self.anonymousId = [self unarchiveAnonymousId];
            self.loginId = [SAFileStore unarchiveWithFileName:kSAEventLoginId];
        });
    }
    return self;
}

#pragma mark - Public Methods

- (BOOL)identify:(NSString *)anonymousId {
    if (![SAValidator isValidString:anonymousId]) {
        SALogError(@"%@ anonymousId:%@ is invalid parameter for identify", self, anonymousId);
        return NO;
    }

    if ([anonymousId length] > 255) {
        SALogWarn(@"%@ anonymousId:%@ is beyond the maximum length 255", self, anonymousId);
    }

    if ([anonymousId isEqualToString:self.anonymousId]) {
        return NO;
    }
    
    // 异步任务设置匿名 ID
    dispatch_async(self.queue, ^{
        self.anonymousId = anonymousId;
        [self archiveAnonymousId:anonymousId];
    });
    return YES;
}

- (void)archiveAnonymousId:(NSString *)anonymousId {
    [SAFileStore archiveWithFileName:kSAEventDistinctId value:anonymousId];
#if TARGET_OS_IOS
    [SAKeyChainItemWrapper saveUdid:anonymousId];
#endif
}

- (void)resetAnonymousId {
    dispatch_async(self.queue, ^{
        NSString *anonymousId = [SAIdentifier hardwareID];
        self.anonymousId = anonymousId;
        [self archiveAnonymousId:anonymousId];
    });
}

- (BOOL)isValidLoginId:(NSString *)loginId {
    if (![SAValidator isValidString:loginId]) {
        SALogError(@"%@ loginId:%@ is invalid parameter for login", self, loginId);
        return NO;
    }

    if ([loginId length] > 255) {
        SALogError(@"%@ loginId:%@ is beyond the maximum length 255", self, loginId);
        return NO;
    }

    if ([loginId isEqualToString:self.loginId]) {
        return NO;
    }

    // 为了避免将匿名 ID 作为 LoginID 传入
    if ([loginId isEqualToString:self.anonymousId]) {
        return NO;
    }

    return YES;
}

- (void)login:(NSString *)loginId {
    dispatch_async(self.queue, ^{
        self.loginId = loginId;
        [SAFileStore archiveWithFileName:kSAEventLoginId value:loginId];
    });
}

- (void)logout {
    dispatch_async(self.queue, ^{
        self.loginId = nil;
        [SAFileStore archiveWithFileName:kSAEventLoginId value:nil];
    });
}


#if TARGET_OS_IOS
+ (NSString *)idfa {
    Class cla = NSClassFromString(@"SAIDFAHelper");
    SEL sel = NSSelectorFromString(@"idfa");
    if ([cla respondsToSelector:sel]) {
        NSString * (*idfaIMP)(id, SEL) = (NSString * (*)(id, SEL))[cla methodForSelector:sel];
        if (idfaIMP) {
            return idfaIMP(cla, sel);
        }
    }
    return nil;
}

+ (NSString *)idfv {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}
#elif TARGET_OS_OSX
/// mac SerialNumber（序列号）作为设备标识
+ (NSString *)serialNumber {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberRef = NULL;
    if (platformExpert) {
        serialNumberRef = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    NSString *serialNumberString = nil;
    if (serialNumberRef) {
        serialNumberString = [NSString stringWithString:(__bridge NSString *)serialNumberRef];
        CFRelease(serialNumberRef);
    }
    return serialNumberString;
}
#endif


+ (NSString *)hardwareID {
    NSString *distinctId = nil;
#if TARGET_OS_IOS
    distinctId = [self idfa];
    // 没有IDFA，则使用IDFV
    if (!distinctId) {
        distinctId = [self idfv];
    }
#elif TARGET_OS_OSX
    distinctId = [self serialNumber];
#endif

    // 如果都没取到，则使用UUID
    if (!distinctId) {
        SALogDebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [NSUUID UUID].UUIDString;
    }
    return distinctId;
}

#pragma mark – Private Methods

- (NSString *)unarchiveAnonymousId {
    NSString *anonymousId = [SAFileStore unarchiveWithFileName:kSAEventDistinctId];

#if TARGET_OS_IOS
    NSString *distinctIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain.length > 0) {
        if (![anonymousId isEqualToString:distinctIdInKeychain]) {
            // 保存 Archiver
            [SAFileStore archiveWithFileName:kSAEventDistinctId value:distinctIdInKeychain];
        }
        anonymousId = distinctIdInKeychain;
    } else {
        if (anonymousId.length == 0) {
            anonymousId = [SAIdentifier hardwareID];
            [self archiveAnonymousId:anonymousId];
        } else {
            //保存 KeyChain
            [SAKeyChainItemWrapper saveUdid:anonymousId];
        }
    }
#else
    if (anonymousId.length == 0) {
        anonymousId = [SAIdentifier hardwareID];
        [self archiveAnonymousId:anonymousId];
    }
#endif

    return anonymousId;
}

#pragma mark – Getters and Setters
- (NSString *)loginId {
    __block NSString *loginId;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        loginId = _loginId;
    });
    return loginId;
}

- (NSString *)anonymousId {
    __block NSString *anonymousId;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        if (!_anonymousId) {
            [self resetAnonymousId];
        }
        anonymousId = _anonymousId;
    });
    return anonymousId;
}

- (NSString *)distinctId {
    __block NSString *distinctId = nil;
    dispatch_block_t block = ^{
        distinctId = self.loginId;
        if (distinctId.length == 0) {
            distinctId = self.anonymousId;
        }
    };
    sensorsdata_dispatch_safe_sync(self.queue, block);
    return distinctId;
}

@end
