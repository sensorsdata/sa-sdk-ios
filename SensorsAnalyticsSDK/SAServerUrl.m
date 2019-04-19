//
//  SAServerUrl.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/1/2.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
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


#import "SAServerUrl.h"
#import "SALogger.h"

@interface SAServerUrl ()

@property (nonatomic, copy, readwrite) NSString *url;
@property (nonatomic, copy, readwrite) NSString *host;
@property (nonatomic, copy, readwrite) NSString *project;
@property (nonatomic, copy, readwrite) NSString *token;

@end

@implementation SAServerUrl

- (BOOL)check:(SAServerUrl *)serverUrl {
    @try {
        if ([_host isEqualToString:serverUrl.host] &&
            [_project isEqualToString:serverUrl.project]) {
            return YES;
        }
    } @catch(NSException *exception) {
        SAError(@"%@: %@", self, exception);
    }
    return NO;
}

- (instancetype)initWithUrl:(NSString *)url {
    if (self = [super init]) {
        _url = url;
        if (url != nil) {
            @try {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithString:url];
                _host = urlComponents.host;
                
                NSDictionary *tempDic = [SAServerUrl analysisQueryItemWithURLComponent:urlComponents];
                if (tempDic.count) {
                    _project = [tempDic objectForKey:@"project"];
                    _token = [tempDic objectForKey:@"token"];
                }
                
            } @catch(NSException *exception) {
                SAError(@"%@: %@", self, exception);
            } @finally {
                if (_host == nil) {
                    _host = @"";
                }
                if (_project == nil) {
                    _project = @"default";
                }
                if (_token == nil) {
                    _token = @"";
                }
            }
        }
    }
    return self;
}

+ (nullable NSDictionary *)analysisQueryItemWithURLComponent:(NSURLComponents *)urlComponents {
    if (urlComponents) {
        NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
        NSString *query = urlComponents.query;
        NSArray *queryArray = [query componentsSeparatedByString:@"&"];
        
        for (NSString *queryItemString in queryArray) {
            NSArray *queryItemArray = [queryItemString componentsSeparatedByString:@"="];
            NSString *queryName = [queryItemArray firstObject];
            NSString *queryValue = [queryItemArray lastObject];
            if (queryName && queryValue) {
                [tempDic setValue:queryValue forKey:queryName];
            }
        }
        
        if (tempDic.count) {
            return tempDic;
        }
    }
    return nil;
}

+ (nullable NSString *)collectURLQueryWithParams:(NSDictionary <NSString *, NSString*>*)params {
    NSMutableArray *queryArray = [[NSMutableArray alloc] init];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *query = [NSString stringWithFormat:@"%@=%@",key,obj];
        [queryArray addObject:query];
    }];
    if (queryArray.count) {
        return [queryArray componentsJoinedByString:@"&"];
    } else {
        return nil;
    }
}
@end
