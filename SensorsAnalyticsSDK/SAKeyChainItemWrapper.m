
//
//  SAKeyChainItemWrapper.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/3/26.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "SALog.h"
#import "SAKeyChainItemWrapper.h"
NSString * const kSAService = @"com.sensorsdata.analytics.udid";
NSString * const kSAUdidAccount = @"com.sensorsdata.analytics.udid";
NSString * const kSAAppInstallationAccount = @"com.sensorsdata.analytics.install";
NSString * const kSAAppInstallationWithDisableCallbackAccount = @"com.sensorsdata.analytics.install.disablecallback";
@implementation SAKeyChainItemWrapper
+ (NSString *)saUdid {
    NSDictionary *result = [self fetchPasswordWithAccount:kSAUdidAccount service:kSAService];
    NSString *sa_udid =  [result objectForKey:(__bridge id)kSecValueData];
    return sa_udid;
}

+ (NSString *)saveUdid:(NSString *)udid {
    BOOL sucess = [self saveOrUpdatePassword:udid account:kSAUdidAccount service:kSAService];
    return sucess ? udid : nil;
}

#ifndef SENSORS_ANALYTICS_DISABLE_INSTALLATION_MARK_IN_KEYCHAIN
+ (BOOL)hasTrackInstallation {
    NSDictionary *result = [self fetchPasswordWithAccount:kSAAppInstallationAccount service:kSAService];
    NSString *value =  [result objectForKey:(__bridge id)kSecValueData];
    return value ? [value boolValue] : NO;
}

+ (BOOL)hasTrackInstallationWithDisableCallback {
    NSDictionary *result = [self fetchPasswordWithAccount:kSAAppInstallationWithDisableCallbackAccount service:kSAService];
    NSString *value =  [result objectForKey:(__bridge id)kSecValueData];
    return value ? [value boolValue] : NO;
}

+ (BOOL)markHasTrackInstallation {
    NSString *str = [NSString stringWithFormat:@"%@", @YES];
    BOOL sucess = [self saveOrUpdatePassword:str account:kSAAppInstallationAccount service:kSAService];
    return sucess;
}

+ (BOOL)markHasTrackInstallationWithDisableCallback {
    NSString *str = [NSString stringWithFormat:@"%@", @YES];
    BOOL sucess = [self saveOrUpdatePassword:str account:kSAAppInstallationWithDisableCallbackAccount service:kSAService];
    return sucess;
}
#endif

+ (BOOL)saveOrUpdatePassword:(NSString *)password account:(NSString *)account service:(NSString *)service {
    return [self saveOrUpdatePassword:password account:account service:service accessGroup:nil];
}

+ (NSDictionary *)fetchPasswordWithAccount:(NSString *)account service:(NSString *)service {
    return [self fetchPasswordWithAccount:account service:service accessGroup:nil];
}

+ (BOOL)deletePasswordWithAccount:(NSString *)account service:(NSString *)service {
    return [self deletePasswordWithAccount:account service:service accessGroup:nil];
}

+ (BOOL)saveOrUpdatePassword:(NSString *)password account:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup {
    @try {
        NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
        CFTypeRef queryResults = NULL;
        CFErrorRef error = NULL;

        if (@available(iOS 8.0, *) ) {
            SecAccessControlRef secAccessControl =  SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlock, kSecAccessControlUserPresence, &error);
            if (error) {
                return NO;
            }
            [query setObject:(__bridge id)secAccessControl forKey:(__bridge id)kSecAttrAccessControl];
            CFRelease(secAccessControl);
        } else {
            @try {
                [query setObject:(__bridge id) kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
            } @catch (NSException *e) {
                SALogError(@"%@", e);
            }
        }

        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

        if (isStringParamValid(account)) {
            [query setObject:account forKey:(__bridge id) kSecAttrAccount];
        }
        if (isStringParamValid(service)) {
            [query setObject:service forKey:(__bridge id) kSecAttrService];
        }
#if !TARGET_IPHONE_SIMULATOR
        if (isStringParamValid(accessGroup)) {
            [query setObject:accessGroup  forKey:(__bridge NSString *)kSecAttrAccessGroup];
        }
#endif
        //search query
        NSMutableDictionary *searchQuery = [[NSMutableDictionary alloc] initWithDictionary:query];
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, &queryResults);
        if (status == errSecSuccess) {
            NSDictionary *attributes = (__bridge_transfer NSDictionary *)queryResults;
            // First we need the attributes from the Keychain.
            NSMutableDictionary *updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
            // Second we need to add the appropriate search key/values.
            [updateItem setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            // Lastly, we need to set up the updated attribute list being careful to remove the class.
            NSMutableDictionary *tempCheck = [[NSMutableDictionary alloc] init] ;
            [tempCheck setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
            [tempCheck removeObjectForKey:(__bridge id)kSecClass];
#if TARGET_IPHONE_SIMULATOR
            // Remove the access group if running on the iPhone simulator.
            //
            // Apps that are built for the simulator aren't signed, so there's no keychain access group
            // for the simulator to check. This means that all apps can see all keychain items when run
            // on the simulator.
            //
            // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
            // simulator will return -25243 (errSecNoAccessForItem).
            //
            // The access group attribute will be included in items returned by SecItemCopyMatching,
            // which is why we need to remove it before updating the item.
            [tempCheck removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
#endif
            // An implicit assumption is that you can only update a single item at a time.
            OSStatus  result = SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
            NSAssert( result == noErr || result == errSecDuplicateItem, @"Couldn't update the Keychain Item." );
            SALogDebug(@"SecItemUpdate result = %d", result);
        } else if(status == errSecItemNotFound) {
            [query setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
            [query removeObjectForKey:(__bridge id)kSecMatchLimit ];
            [query removeObjectForKey:(__bridge id)kSecReturnAttributes];
            [query removeObjectForKey:(__bridge id)kSecReturnData];

            if (@available(iOS 8.0, *) ) {
                [query removeObjectForKey:(__bridge id)kSecAttrAccessControl];
            } else {
                @try {
                    [query removeObjectForKey:(__bridge id)kSecAttrAccessible];
                } @catch (NSException *e) {
                    SALogError(@"%@", e);
                }
            }

            status= SecItemAdd((__bridge CFDictionaryRef)query, &queryResults);
            NSAssert( status == noErr || status == errSecDuplicateItem, @"Couldn't add the Keychain Item." );
            SALogDebug(@"SecItemAdd result = %d", status);
        }
        return (status == errSecSuccess);
    } @catch (NSException *e) {
        SALogError(@"%@", e);
        return NO;
    }
}

+ (NSDictionary *)fetchPasswordWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup {
    @try {
        NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
        CFTypeRef queryResults = NULL;
        CFErrorRef error = NULL;
        if (@available(iOS 8.0, *) ) {
            SecAccessControlRef secAccessControl =  SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlock, kSecAccessControlUserPresence, &error);
            if (error) {
                return nil;
            }
            [query setObject:(__bridge id)secAccessControl forKey:(__bridge id)kSecAttrAccessControl];
            CFRelease(secAccessControl);
        } else {
            @try {
                [query setObject:(__bridge id) kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
            } @catch (NSException *e) {
                SALogError(@"%@", e);
            }
        }
        
        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit ];
        
#if !TARGET_IPHONE_SIMULATOR
        if (isStringParamValid(accessGroup)) {
            [query setObject:accessGroup  forKey:(__bridge NSString *)kSecAttrAccessGroup];
        }
#endif
        if (isStringParamValid(account)) {
            [query setObject:account forKey:(__bridge id) kSecAttrAccount];
        }
        if (isStringParamValid(service)) {
            [query setObject:service forKey:(__bridge id) kSecAttrService];
        }
        NSMutableDictionary * mutResultDict = [NSMutableDictionary dictionary];
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &queryResults);
        if (status == errSecSuccess) {
            NSDictionary *results = (__bridge_transfer NSDictionary *)queryResults;
            [mutResultDict addEntriesFromDictionary:results];
            NSString * password = [[NSString alloc] initWithData:[results objectForKey:(__bridge id)kSecValueData] encoding:NSUTF8StringEncoding];
            [mutResultDict setObject:password forKey:(__bridge id)kSecValueData];
        } else if(status == errSecItemNotFound) {
        }
        return mutResultDict;
    } @catch (NSException *e) {
        SALogError(@"%@", e);
        return nil;
    }
}

+ (BOOL)deletePasswordWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup {
    @try {
        NSMutableDictionary *searchQuery = [[NSMutableDictionary alloc] init];
        [searchQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        if(isStringParamValid(service)) {
            [searchQuery setObject:service forKey:(__bridge id)kSecAttrService];
        }
        if(isStringParamValid(account)) {
            [searchQuery setObject:account forKey:(__bridge id)kSecAttrAccount];
        }
#if !TARGET_IPHONE_SIMULATOR
        if(isStringParamValid(accessGroup)) {
            [searchQuery setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
        }
#endif
        OSStatus status = SecItemDelete((__bridge  CFDictionaryRef)  searchQuery);
        return (status == errSecSuccess);
    } @catch (NSException *e) {
        SALogError(@"%@", e);
        return NO;
    }
}

static BOOL isStringParamValid(id  parameter) {
    BOOL result = NO;
    if ([parameter isKindOfClass:[NSString class]] && [parameter length] > 0) {
            result = YES;
    }
    return result;
}

@end
