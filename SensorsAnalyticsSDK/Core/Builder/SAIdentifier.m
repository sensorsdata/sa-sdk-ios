//
// SAIdentifier.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/2/17.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAIdentifier.h"
#import "SAConstants+Private.h"
#import "SAStoreManager.h"
#import "SAValidator.h"
#import "SALog.h"
#import "SensorsAnalyticsSDK+Private.h"

#if TARGET_OS_IOS
#import "SAKeyChainItemWrapper.h"
#import <UIKit/UIKit.h>
#endif

NSString * const kSAIdentities = @"com.sensorsdata.identities";
NSString * const kSAIdentitiesLoginId = @"$identity_login_id";
NSString * const kSAIdentitiesAnonymousId = @"$identity_anonymous_id";
NSString * const kSAIdentitiesCookieId = @"$identity_cookie_id";

#if TARGET_OS_OSX
NSString * const kSAIdentitiesOldUniqueID = @"$mac_serial_id";
NSString * const kSAIdentitiesUniqueID = @"$identity_mac_serial_id";
NSString * const kSAIdentitiesUUID = @"$identity_mac_uuid";
#else
NSString * const kSAIdentitiesUniqueID = @"$identity_idfv";
NSString * const kSAIdentitiesUUID = @"$identity_ios_uuid";
#endif

NSString * const kSALoginIDKey = @"com.sensorsdata.loginidkey";
NSString * const kSAIdentitiesCacheType = @"Base64:";

NSString * const kSALoginIdSpliceKey = @"+";

@interface SAIdentifier ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, copy, readwrite) NSString *loginId;
@property (nonatomic, copy, readwrite) NSString *anonymousId;
@property (nonatomic, copy, readwrite) NSString *loginIDKey;

// ID-Mapping 3.0 拼接前客户传入的原始 LoginID
@property (nonatomic, copy) NSString *originalLoginId;

@property (nonatomic, copy, readwrite) NSDictionary *identities;
@property (nonatomic, copy) NSDictionary *removedIdentity;

@end

@implementation SAIdentifier

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        dispatch_async(_queue, ^{
            // 获取 self.identities 需要判断当前本地文件是否存在 anonymousId
            // 获取 self.anonymousId 会写入本地文件，因此需要先获取 self.identities
            self.loginIDKey = [self unarchiveLoginIDKey];
            self.identities = [self unarchiveIdentitiesWithKey:self.loginIDKey];
            self.anonymousId = [self unarchiveAnonymousId];
            NSString *cacheLoginId = [[SAStoreManager sharedInstance] objectForKey:kSAEventLoginId];
            self.originalLoginId = cacheLoginId;
            if ([self.loginIDKey isEqualToString:kSAIdentitiesLoginId]) {
                self.loginId = cacheLoginId;
            } else {
                self.loginId = [NSString stringWithFormat:@"%@%@%@", self.loginIDKey, kSALoginIdSpliceKey, cacheLoginId];
            }
        });
    }
    return self;
}

#pragma mark - Public Methods

- (BOOL)identify:(NSString *)anonymousId {
    if (![anonymousId isKindOfClass:[NSString class]]) {
        SALogError(@"AnonymousId must be string");
        return NO;
    }
    if (anonymousId.length == 0) {
        SALogError(@"AnonymousId is empty");
        return NO;
    }

    if ([anonymousId length] > kSAPropertyValueMaxLength) {
        SALogWarn(@"AnonymousId: %@'s length is longer than %ld", anonymousId, kSAPropertyValueMaxLength);
    }

    if ([anonymousId isEqualToString:self.anonymousId]) {
        return NO;
    }
    
    [self updateAnonymousId:anonymousId];
    [self bindIdentity:kSAIdentitiesAnonymousId value:anonymousId];
    return YES;
}

- (void)archiveAnonymousId:(NSString *)anonymousId {
    [[SAStoreManager sharedInstance] setObject:anonymousId forKey:kSAEventDistinctId];
#if TARGET_OS_IOS
    [SAKeyChainItemWrapper saveUdid:anonymousId];
#endif
}

- (void)resetAnonymousId {
    NSString *anonymousId = [SAIdentifier hardwareID];
    [self updateAnonymousId:anonymousId];
    // 只有 identities 包含 $identity_anonymous_id 时需要更新内容
    if (self.identities[kSAIdentitiesAnonymousId]) {
        [self bindIdentity:kSAIdentitiesAnonymousId value:anonymousId];
    }
}

- (void)updateAnonymousId:(NSString *)anonymousId {
    // 异步任务设置匿名 ID
    dispatch_async(self.queue, ^{
        self.anonymousId = anonymousId;
        [self archiveAnonymousId:anonymousId];
    });
}

- (BOOL)isValidLoginId:(NSString *)loginId {
    if (![loginId isKindOfClass:[NSString class]]) {
        SALogError(@"LoginId must be string");
        return NO;
    }
    if (loginId.length == 0) {
        SALogError(@"LoginId is empty");
        return NO;
    }
    if ([loginId length] > kSAPropertyValueMaxLength) {
        SALogWarn(@"LoginId: %@'s length is longer than %ld", loginId, kSAPropertyValueMaxLength);
    }
    // 为了避免将匿名 ID 作为 LoginID 传入
    if ([loginId isEqualToString:self.anonymousId]) {
        return NO;
    }
    return YES;
}

- (BOOL)isValidLoginIDKey:(NSString *)key {
    NSError *error = nil;
    [SAValidator validKey:key error:&error];
    if (error) {
        SALogError(@"%@",error.localizedDescription);
        if (error.code != SAValidatorErrorOverflow) {
            return NO;
        }
    }
    if ([self isDeviceIDKey:key] || [self isAnonymousIDKey:key]) {
        SALogError(@"LoginIDKey [ %@ ] is invalid", key);
        return NO;
    }
    return YES;
}

- (BOOL)isValidForLogin:(NSString *)key value:(NSString *)value {
    if (![self isValidLoginIDKey:key]) {
        return NO;
    }
    if (![self isValidLoginId:value]) {
        return NO;
    }
    // 当 loginIDKey 和 loginId 均未发生变化时，不需要触发事件
    if ([self.loginIDKey isEqualToString:key] && [self.originalLoginId isEqualToString:value]) {
        return NO;
    }
    return  YES;
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId {
    [self updateLoginInfo:key loginId:loginId];
    [self bindIdentity:key value:loginId];
}

- (void)updateLoginInfo:(NSString *)loginIDKey loginId:(NSString *)loginId {
    dispatch_async(self.queue, ^{
        if ([loginIDKey isEqualToString:kSAIdentitiesLoginId]) {
            self.loginId = loginId;
        } else {
            self.loginId = [NSString stringWithFormat:@"%@%@%@", loginIDKey, kSALoginIdSpliceKey,loginId];
        }
        self.originalLoginId = loginId;
        self.loginIDKey = loginIDKey;
        // 本地缓存的 login_id 值为原始值，在初始化时处理拼接逻辑
        [[SAStoreManager sharedInstance] setObject:loginId forKey:kSAEventLoginId];
        // 登录时本地保存当前的 loginIDKey 字段，字段存在时表示 v3.0 版本 SDK 已进行过登录
        [[SAStoreManager sharedInstance] setObject:loginIDKey forKey:kSALoginIDKey];
    });
}

- (void)logout {
    [self clearLoginInfo];
    [self resetIdentities];
}

- (void)clearLoginInfo {
    dispatch_async(self.queue, ^{
        self.loginId = nil;
        self.originalLoginId = nil;
        self.loginIDKey = kSAIdentitiesLoginId;
        [[SAStoreManager sharedInstance] removeObjectForKey:kSAEventLoginId];
        // 退出登录时清除本地保存的 loginIDKey 字段，字段不存在时表示 v3.0 版本 SDK 已退出登录
        [[SAStoreManager sharedInstance] removeObjectForKey:kSALoginIDKey];
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
    NSString *anonymousId = [[SAStoreManager sharedInstance] objectForKey:kSAEventDistinctId];

#if TARGET_OS_IOS
    NSString *distinctIdInKeychain = [SAKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain.length > 0) {
        if (![anonymousId isEqualToString:distinctIdInKeychain]) {
            // 保存 Archiver
            [[SAStoreManager sharedInstance] setObject:distinctIdInKeychain forKey:kSAEventDistinctId];
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

- (NSString *)originalLoginId {
    __block NSString *originalLoginId;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        originalLoginId = _originalLoginId;
    });
    return originalLoginId;
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

- (NSDictionary *)identities {
    __block NSDictionary *identities;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        identities = _identities;
    });
    return identities;
}

- (NSString *)loginIDKey {
    __block NSString *loginIDKey;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        loginIDKey = _loginIDKey;
    });
    return loginIDKey;
}

- (NSDictionary *)removedIdentity {
    __block NSDictionary *removedIdentity;
    sensorsdata_dispatch_safe_sync(self.queue, ^{
        removedIdentity = _removedIdentity;
    });
    return removedIdentity;
}

#pragma mark - Identities
- (NSDictionary *)mergeH5Identities:(NSDictionary *)identities eventType:(NSString *)eventType {
    if ([eventType isEqualToString:kSAEventTypeUnbind]) {
        NSString *key = identities.allKeys.firstObject;
        if (![self isValidForUnbind:key value:identities[key]]) {
            return @{};
        }
        [self unbindIdentity:key value:identities[key]];
        return identities;
    }

    NSMutableDictionary *newIdentities = [NSMutableDictionary dictionaryWithDictionary:identities];
    // 移除 H5 事件 identities 中的保留 ID，不允许 H5 绑定保留 ID
    [newIdentities removeObjectsForKeys:@[kSAIdentitiesUniqueID, kSAIdentitiesUUID, kSAIdentitiesAnonymousId]];
    [newIdentities addEntriesFromDictionary:self.identities];

    // 当 identities 不存在（ 2.0 版本）或 identities 中包含自定义 login_id （3.0 版本）时
    // 即表示有效登录，需要重置 identities 内容
    BOOL reset = (!identities || identities[self.loginIDKey]);
    if ([eventType isEqualToString:kSAEventTypeSignup] && reset) {
        // 当前逻辑需要在调用 login 后执行才是有效的，重置 identities 时需要使用 login_id
        // 触发登录事件切换用户时，清空后续事件中的已绑定参数
        [self resetIdentities];
    }

    // 当为绑定事件时，Native 需要把绑定的业务 ID 持久化
    if ([eventType isEqualToString:kSAEventTypeBind]) {
        dispatch_async(self.queue, ^{
            NSMutableDictionary *archive = [newIdentities mutableCopy];
            [archive removeObjectForKey:kSAIdentitiesCookieId];
            self.identities = archive;
            [self archiveIdentities:archive];
        });
    }
    return newIdentities;
}

- (BOOL)isDeviceIDKey:(NSString *)key {
    return ([key isEqualToString:kSAIdentitiesUniqueID] ||
            [key isEqualToString:kSAIdentitiesUUID]
       #if TARGET_OS_OSX
            || [key isEqualToString:kSAIdentitiesOldUniqueID]
       #endif
            );
}

- (BOOL)isAnonymousIDKey:(NSString *)key {
    // $identity_anonymous_id 为兼容 2.0 identify() 的产物，也不允许客户绑定与解绑
    return [key isEqualToString:kSAIdentitiesAnonymousId];
}

- (BOOL)isLoginIDKey:(NSString *)key {
    // $identity_login_id 为业务唯一标识，不允许客户绑定或解绑，只能通过 login 接口关联
    return [key isEqualToString:kSAIdentitiesLoginId];
}

- (BOOL)isValidForBind:(NSString *)key value:(NSString *)value {
    if (![key isKindOfClass:NSString.class]) {
        SALogError(@"Key [%@] must be string", key);
        return NO;
    }
    if (key.length <= 0) {
        SALogError(@"Key is empty");
        return NO;
    }
    if ([self isDeviceIDKey:key] || [self isAnonymousIDKey:key] || [self isLoginIDKey:key]) {
        SALogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    if ([key isEqualToString:self.loginIDKey]) {
        SALogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    return [self isValidIdentity:key value:value];
}

- (BOOL)isValidForUnbind:(NSString *)key value:(NSString *)value {
    if (![key isKindOfClass:NSString.class]) {
        SALogError(@"Key [%@] must be string", key);
        return NO;
    }
    if (key.length <= 0) {
        SALogError(@"Key is empty");
        return NO;
    }
    return [self isValidIdentity:key value:value];
}

- (BOOL)isValidIdentity:(NSString *)key value:(NSString *)value {
    NSError *error = nil;
    [SAValidator validKey:key error:&error];
    if (error) {
        SALogError(@"%@",error.localizedDescription);
    }
    if (error && error.code != SAValidatorErrorOverflow) {
        return NO;
    }
    // 不允许绑定/解绑 $identity_anonymous_id 和 $identity_login_id
    if ([self isAnonymousIDKey:key] || [self isLoginIDKey:key]) {
        SALogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    if (!value) {
        SALogError(@"bind or unbind value should not be nil");
        return NO;
    }
    if (![value isKindOfClass:[NSString class]]) {
        SALogError(@"bind or unbind value should be string");
        return NO;
    }
    if (value.length == 0) {
        SALogError(@"bind or unbind value should not be empty");
        return NO;
    }
    [value sensorsdata_propertyValueWithKey:key error:nil];
    return YES;
}

- (void)bindIdentity:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *identities = [self.identities mutableCopy];
    identities[key] = value;
    dispatch_async(self.queue, ^{
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (void)unbindIdentity:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *removed = [NSMutableDictionary dictionary];
    removed[key] = value;
    if (![value isEqualToString:self.identities[key]] || [self isDeviceIDKey:key]) {
        // 当 identities 中不存在需要解绑的字段时，不需要进行删除操作
        dispatch_async(self.queue, ^{
            self.removedIdentity = removed;
        });
        return;
    }

    // 当解绑自定义 loginIDKey 时，需要同步清除 2.0 的 login_id 信息
    NSString *result = [NSString stringWithFormat:@"%@%@%@", key, kSALoginIdSpliceKey, value];
    if ([result isEqualToString:self.loginId]) {
        [self clearLoginInfo];
    }

    NSMutableDictionary *identities = [self.identities mutableCopy];
    [identities removeObjectForKey:key];
    dispatch_async(self.queue, ^{
        self.removedIdentity = removed;
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (void)resetIdentities {
    NSMutableDictionary *identities = [NSMutableDictionary dictionary];
    identities[kSAIdentitiesUniqueID] = self.identities[kSAIdentitiesUniqueID];
    identities[kSAIdentitiesUUID] = self.identities[kSAIdentitiesUUID];
    // 当 loginId 存在时需要添加 loginId
    identities[self.loginIDKey] = self.originalLoginId;
    dispatch_async(self.queue, ^{
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (NSDictionary *)identitiesWithEventType:(NSString *)eventType {
    // 提前拷贝当前事件的 identities 内容，避免登录事件时被清空其他业务 ID
    NSDictionary *identities = [self.identities copy];

    if ([eventType isEqualToString:kSAEventTypeUnbind]) {
        identities = [self.removedIdentity copy];
        self.removedIdentity = nil;
    }
    // 客户业务场景下切换用户后，需要清除其他已绑定业务 ID
    if ([eventType isEqualToString:kSAEventTypeSignup]) {
        [self resetIdentities];
    }
    return identities;
}

- (NSString *)unarchiveLoginIDKey {
    NSString *content = [[SAStoreManager sharedInstance] objectForKey:kSALoginIDKey];
    if (content.length < 1) {
        content = kSAIdentitiesLoginId;
        [[SAStoreManager sharedInstance] setObject:content forKey:kSALoginIDKey];
    }
    return content;
}

- (NSDictionary *)unarchiveIdentitiesWithKey:(NSString *)loginIDKey {
    NSDictionary *cache = [self decodeIdentities];
    NSMutableDictionary *identities = [NSMutableDictionary dictionaryWithDictionary:cache];

    // 当 cache 不存在时表示从 v2.0 升级到 v3.0 版本，兼容 v2.0 的 anonymous_id
    // 存在从 v3.0 降级至 v2.0 且修改了 anonymous_id 又升级回 v3.0 的情况
    // 所以当 identities[kSAIdentitiesAnonymousId] 存在时，需要使用本地的 anonymous_id 更新其内容
    if (!cache || identities[kSAIdentitiesAnonymousId]) {

        NSString *anonymousId;
#if TARGET_OS_IOS
        // 读取 KeyChain 中保存的 anonymousId，
        // 当前逻辑时 self.anonymousId 还未设置，因此需要手动读取 keychain 数据
        anonymousId = [SAKeyChainItemWrapper saUdid];
#endif
        if (!anonymousId) {
            // 读取本地文件中保存的 anonymouId
            anonymousId = [[SAStoreManager sharedInstance] objectForKey:kSAEventDistinctId];
        }
        identities[kSAIdentitiesAnonymousId] = anonymousId;
    }

    // SDK 取 IDFV 或 uuid 为设备唯一标识，已知情况下未发现获取不到 IDFV 的情况
    if (!identities[kSAIdentitiesUniqueID] && !identities[kSAIdentitiesUUID] ) {
        NSString *key = kSAIdentitiesUUID;
        NSString *value = [NSUUID UUID].UUIDString;
#if TARGET_OS_IOS
        if ([SAIdentifier idfv]) {
            key = kSAIdentitiesUniqueID;
            value = [SAIdentifier idfv];
        }
#elif TARGET_OS_OSX
        if ([SAIdentifier serialNumber]) {
            key = kSAIdentitiesUniqueID;
            value = [SAIdentifier serialNumber];
        }
#endif
        identities[key] = value;
    }

    NSString *loginId = [[SAStoreManager sharedInstance] objectForKey:kSAEventLoginId];
    // 本地存在 loginId 时表示 v2.0 版本为登录状态，可能需要将登录状态同步 v3.0 版本的 identities 中
    // 为了避免客户升级 v3.0 后又降级至 v2.0，然后又升级至 v3.0 版本的兼容问题，这里每次冷启动都处理一次

    // 当 v3.0 版本进行过登录操作时，本地一定会存在登录时使用的 loginIDKey 内容
    NSString *cachedKey = [[SAStoreManager sharedInstance] objectForKey:kSALoginIDKey];
    if (loginId) {
        if (identities[cachedKey]) {
            // 场景：
            // v3.0 版本设置 loginIDKey 为 a_id 并进行登录 123, 降级至 v2.0 版本并重新登录 456, 再次升级至 v3.0 版本后 loginIDKey 仍为 a_id
            // 此时 identities 中存在 a_id 内容，需要更新 a_id 内容
            if (![identities[cachedKey] isEqualToString:loginId]) {
                // 当 identities 中 cachedKey 内容和 v2.0 版本 loginId 内容不一致时，表示登录用户发生了变化，需要更新 cachedKey 对应内容并清空其他所有业务 ID
                NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
                newIdentities[kSAIdentitiesUniqueID] = identities[kSAIdentitiesUniqueID];
                newIdentities[kSAIdentitiesUUID] = identities[kSAIdentitiesUUID];
                // identities 中存在 cachedKey 内容时，只需要更新 cachedKey 对应的内容。
                newIdentities[cachedKey] = loginId;
                identities = newIdentities;
            }
        } else {
            // 场景：
            // v3.0 版本设置 loginIDKey 为 $identity_login_id 且未进行登录, 降级至 v2.0 版本并重新登录 456, 再次升级至 v3.0 版本后 loginIDKey 仍为 $identity_login_id
            // 此时 identities 中不存在 cacheKey 对应内容，表示 v3.0 版本未进行过登录操作。要将 v2.0 版本登录状态 { $identity_login_id:456 } 同步至 v3.0 版本的 identities 中
            NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
            newIdentities[kSAIdentitiesUniqueID] = identities[kSAIdentitiesUniqueID];
            newIdentities[kSAIdentitiesUUID] = identities[kSAIdentitiesUUID];
            newIdentities[loginIDKey] = loginId;
            identities = newIdentities;

            // 此时相当于进行登录操作，需要保存登录时设置的 loginIDKey 内容至本地文件中
            [[SAStoreManager sharedInstance] setObject:loginIDKey forKey:kSALoginIDKey];
        }
    } else {
        if (identities[cachedKey]) {
            // 场景：v3.0 版本登录时，降级至 v2.0 版本并退出登录，然后再升级至 v3.0 版本
            // 此时 identities 中仍为登录状态，需要进行退出登录操作
            // 只需要保留 $identity_idfv/$identity_ios_uuid 和 $identity_anonymous_id
            NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
            newIdentities[kSAIdentitiesUniqueID] = identities[kSAIdentitiesUniqueID];
            newIdentities[kSAIdentitiesUUID] = identities[kSAIdentitiesUUID];
            newIdentities[kSAIdentitiesAnonymousId] = identities[kSAIdentitiesAnonymousId];
            identities = newIdentities;
        }
        // 当 v2.0 版本状态为未登录状态时，直接清空本地保存的 loginIDKey 文件内容
        // v3.0 版本清空本地保存的 loginIDKey 会在 logout 中处理
        [[SAStoreManager sharedInstance] removeObjectForKey:kSALoginIDKey];
    }
#if TARGET_OS_OSX
        // 4.1.0 以后的版本将 $mac_serial_id 替换为了 $identity_mac_serial_id
        // 此处不考虑是否是用户绑定的 key, 直接移除
        if (identities[kSAIdentitiesOldUniqueID]) {
            [identities removeObjectForKey:kSAIdentitiesOldUniqueID];
        }
#endif
    // 每次强制更新一次本地 identities，触发部分业务场景需要更新本地内容
    [self archiveIdentities:identities];
    return identities;
}

- (NSDictionary *)decodeIdentities {
    NSString *content = [[SAStoreManager sharedInstance] objectForKey:kSAIdentities];
    if (![content isKindOfClass:NSString.class]) {
        return nil;
    }
    NSData *data;
    if ([content hasPrefix:kSAIdentitiesCacheType]) {
        NSString *value = [content substringFromIndex:kSAIdentitiesCacheType.length];
        data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (void)archiveIdentities:(NSDictionary *)identities {
    if (!identities) {
        return;
    }

    @try {
        NSData *data = [NSJSONSerialization dataWithJSONObject:identities options:NSJSONWritingPrettyPrinted error:nil];
        NSString *base64Str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        NSString *result = [NSString stringWithFormat:@"%@%@",kSAIdentitiesCacheType, base64Str];
        [[SAStoreManager sharedInstance] setObject:result forKey:kSAIdentities];
    } @catch (NSException *exception) {
        SALogError(@"%@", exception);
    }
}

@end
