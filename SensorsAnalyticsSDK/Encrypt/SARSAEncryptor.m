//
// SARSAEncryptor.m
// SensorsAnalyticsSDK
//
// Created by wenquan on 2020/12/2.
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

#import "SARSAEncryptor.h"
#import <Security/Security.h>
#import "SAValidator.h"
#import "SALog.h"

@interface SARSAEncryptor ()

@end

@implementation SARSAEncryptor

- (void)setKey:(NSString *)key {
    if (![SAValidator isValidString:key]) {
        return;
    }
    NSString *publicKeyCopy = [key copy];
    publicKeyCopy = [publicKeyCopy stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    publicKeyCopy = [publicKeyCopy stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    publicKeyCopy = [publicKeyCopy stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    publicKeyCopy = [publicKeyCopy stringByReplacingOccurrencesOfString:@" "  withString:@""];
    _key = publicKeyCopy;
}

- (NSString *)algorithm {
    return kSAAlgorithmTypeRSA;
}

- (NSString *)encryptData:(NSData *)data {
    if (![SAValidator isValidData:data]) {
        SALogError(@"Enable RSA encryption but the input obj is invalid!");
        return nil;
    }

    NSString *asymmetricPublicKey = self.key;
    if (![SAValidator isValidString:asymmetricPublicKey]) {
        SALogError(@"Enable RSA encryption but the public key is invalid!");
        return nil;
    }
    
    SecKeyRef keyRef = [self addPublicKey:asymmetricPublicKey];
    if (!keyRef) {
        SALogError(@"Enable RSA encryption but init public SecKeyRef failed!");
        return nil;
    }
    
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for(int idx=0; idx<srclen; idx+=src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        
        status = SecKeyEncrypt(keyRef,
                               kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            SALogError(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
            ret = nil;
            break;
        }else{
            [ret appendBytes:outbuf length:outlen];
        }
    }
    free(outbuf);
    CFRelease(keyRef);
    
    return [ret base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

#pragma mark – Private Methods
- (SecKeyRef)addPublicKey:(NSString *)aymmetricPublicKey {
    NSString *key = [aymmetricPublicKey copy];
    
    // This will be base64 encoded, decode it.
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self stripPublicKeyHeader:data];
    if (!data) {
        return nil;
    }
    
    //a tag to read/write keychain storage
    NSString *tag = @"Sensors_RSAUtil_PubKey";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [publicKey setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

- (NSData *)stripPublicKeyHeader:(NSData *)d_key {
    // Skip ASN.1 public key header
    if (d_key == nil) {
        return(nil);
    }

    unsigned long len = [d_key length];
    if (!len) {
        return(nil);
    }

    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int idx = 0;
    
    if (c_key[idx++] != 0x30) {
        return(nil);
    }

    if (c_key[idx] > 0x80) {
        idx += c_key[idx] - 0x80 + 1;
    } else {
        idx++;
    }

    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) {
        return(nil);
    }
    idx += 15;
    
    if (c_key[idx++] != 0x03) {
        return(nil);
    }

    if (c_key[idx] > 0x80) {
        idx += c_key[idx] - 0x80 + 1;
    } else {
        idx++;
    }
    if (c_key[idx++] != '\0') {
        return(nil);
    }
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

@end
