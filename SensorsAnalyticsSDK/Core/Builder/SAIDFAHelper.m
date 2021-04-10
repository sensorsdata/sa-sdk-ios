//
// SAIDFAHelper.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/12/1.
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

#import "SAIDFAHelper.h"

@implementation SAIDFAHelper

+ (NSString *)idfa {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    if (![ASIdentifierManagerClass respondsToSelector:sharedManagerSelector]) {
        return nil;
    }
    id (*sharedManagerIMP)(id, SEL) = (id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector];
    if (!sharedManagerIMP) {
        return nil;
    }
    id sharedManager = sharedManagerIMP(ASIdentifierManagerClass, sharedManagerSelector);
    
    SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
    if (![sharedManager respondsToSelector:advertisingIdentifierSelector]) {
        return nil;
    }
    NSUUID * (*advertisingIdentifierIMP)(id, SEL) = (NSUUID * (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector];
    if (!advertisingIdentifierIMP) {
        return nil;
    }
    NSUUID *uuid = advertisingIdentifierIMP(sharedManager, advertisingIdentifierSelector);
    NSString *idfa = [uuid UUIDString];
    // 在 iOS 10.0 以后，当用户开启限制广告跟踪，advertisingIdentifier 的值将是全零
    // 00000000-0000-0000-0000-000000000000
    if ([idfa hasPrefix:@"00000000"]) {
        return nil;
    }
    
    return idfa;
}

@end
