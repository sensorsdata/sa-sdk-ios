//
//  SACommonUtility.m
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/7/26.
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

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "SACommonUtility.h"
#import "SAReachability.h"
#import "SAConstants.h"
#import "SALog.h"
#import "SAValidator.h"

@implementation SACommonUtility


///按字节截取指定长度字符，包括汉字
+ (NSString *)subByteString:(NSString *)string byteLength:(NSInteger )length {
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
    NSData* data = [string dataUsingEncoding:enc];
    
    NSData *subData = [data subdataWithRange:NSMakeRange(0, length)];
    NSString*txt=[[NSString alloc] initWithData:subData encoding:enc];
    
     //utf8 汉字占三个字节，表情占四个字节，可能截取失败
    NSInteger index = 1;
    while (index <= 3 && !txt) {
        if (length > index) {
            subData = [data subdataWithRange:NSMakeRange(0, length - index)];
            txt = [[NSString alloc] initWithData:subData encoding:enc];
        }
        index ++;
    }
    
    if (!txt) {
        return string;
    }
    return txt;
}

+ (NSDictionary<NSString *, NSString *> *)radioAccessTechnologyMap {
    static dispatch_once_t onceToken;
    static NSDictionary<NSString *, NSString *> *map;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSString *, NSString *> *dic = [NSMutableDictionary dictionaryWithDictionary:@{
            CTRadioAccessTechnologyGPRS: @"2G",
            CTRadioAccessTechnologyEdge: @"2G",
            CTRadioAccessTechnologyWCDMA: @"3G",
            CTRadioAccessTechnologyHSDPA: @"3G",
            CTRadioAccessTechnologyHSUPA: @"3G",
            CTRadioAccessTechnologyCDMA1x: @"3G",
            CTRadioAccessTechnologyCDMAEVDORev0: @"3G",
            CTRadioAccessTechnologyCDMAEVDORevA: @"3G",
            CTRadioAccessTechnologyCDMAEVDORevB: @"3G",
            CTRadioAccessTechnologyeHRPD: @"3G",
            CTRadioAccessTechnologyLTE: @"4G",
        }];
#ifdef __IPHONE_14_1
        if (@available(iOS 14.1, *)) {
            dic[CTRadioAccessTechnologyNRNSA] = @"5G";
            dic[CTRadioAccessTechnologyNR] = @"5G";
        }
#endif
        map = [dic copy];
    });
    return map;
}

+ (NSString *)currentNetworkStatus {
#ifdef SA_UT
    SALogDebug(@"In unit test, set NetWorkStates to wifi");
    return @"WIFI";
#endif
    NSString *network = @"NULL";
    @try {
        SAReachability *reachability = [SAReachability reachabilityForInternetConnection];
        SANetworkStatus status = [reachability currentReachabilityStatus];
        
        if (status == SAReachableViaWiFi) {
            network = @"WIFI";
        } else if (status == SAReachableViaWWAN) {
            static CTTelephonyNetworkInfo *netinfo = nil;
            NSString *currentRadioAccessTechnology = nil;
            
            if (!netinfo) {
                netinfo = [[CTTelephonyNetworkInfo alloc] init];
            }
#ifdef __IPHONE_12_0
            if (@available(iOS 12.1, *)) {
                currentRadioAccessTechnology = netinfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
            }
#endif
            //测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
            if (!currentRadioAccessTechnology) {
                currentRadioAccessTechnology = netinfo.currentRadioAccessTechnology;
            }

            network = [self radioAccessTechnologyMap][currentRadioAccessTechnology] ?: @"UNKNOWN";
        }
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
    return network;
}

+ (void)performBlockOnMainThread:(DISPATCH_NOESCAPE dispatch_block_t)block {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (SensorsAnalyticsNetworkType)toNetworkType:(NSString *)networkType {
    if ([@"NULL" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeNONE;
    } else if ([@"WIFI" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkTypeWIFI;
    } else if ([@"2G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType2G;
    } else if ([@"3G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType3G;
    } else if ([@"4G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType4G;
#ifdef __IPHONE_14_1
    } else if ([@"5G" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType5G;
#endif
    } else if ([@"UNKNOWN" isEqualToString:networkType]) {
        return SensorsAnalyticsNetworkType4G;
    }
    return SensorsAnalyticsNetworkTypeNONE;
}

+ (SensorsAnalyticsNetworkType)currentNetworkType {
    NSString *currentNetworkStatus = [SACommonUtility currentNetworkStatus];
    return [SACommonUtility toNetworkType:currentNetworkStatus];
}

+ (NSString *)currentUserAgent {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
}

+ (void)saveUserAgent:(NSString *)userAgent {
    if (![SAValidator isValidString:userAgent]) {
        return;
    }
    
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:userAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
