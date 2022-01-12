//
// SAURLUtils.m
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2019/4/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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

#import "SAURLUtils.h"

@implementation SAURLUtils

+ (NSString *)hostWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    return [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO].host;
}

+ (NSString *)hostWithURLString:(NSString *)URLString {
    if (URLString.length == 0) {
        return nil;
    }
    return [NSURLComponents componentsWithString:URLString].host;
}

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    return [self queryItemsWithURLComponents:components];
}

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString {
    if (URLString.length == 0) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    return [self queryItemsWithURLComponents:components];
}

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLComponents:(NSURLComponents *)components {
    if (!components) {
        return nil;
    }
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    NSArray<NSString *> *queryArray = [components.percentEncodedQuery componentsSeparatedByString:@"&"];
    for (NSString *itemString in queryArray) {
        NSArray<NSString *> *itemArray = [itemString componentsSeparatedByString:@"="];
        if (itemArray.count >= 2) {
            items[itemArray.firstObject] = itemArray.lastObject;
        }
    }
    return items;
}

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params {
    NSMutableArray *queryArray = [[NSMutableArray alloc] init];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
        NSString *query = [NSString stringWithFormat:@"%@=%@", key, obj];
        [queryArray addObject:query];
    }];
    if (queryArray.count) {
        return [queryArray componentsJoinedByString:@"&"];
    } else {
        return nil;
    }
}

+ (NSDictionary<NSString *, NSString *> *)decodeRueryItemsWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    return [self decodeRueryItemsWithURLComponents:components];
}

+ (NSDictionary<NSString *, NSString *> *)decodeRueryItemsWithURLComponents:(NSURLComponents *)components{

    if (!components) {
        return nil;
    }
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    if (queryItems.count) {
        NSMutableDictionary *queryItemsDic = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in queryItems) {
            queryItemsDic[item.name] = item.value;
        }
        return queryItemsDic;
    } else {
        return nil;
    }
}

@end
