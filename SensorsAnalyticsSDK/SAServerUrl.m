//
//  SAServerUrl.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/1/2.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

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
//        if (_token != nil &&
//            ![_token isEqualToString:@""]
//            && serverUrl.token != nil &&
//            ![serverUrl.token isEqualToString:@""]) {
//            if ([_token isEqualToString:serverUrl.token]) {
//                return YES;
//            }
//        } else {
            if ([_host isEqualToString:serverUrl.host] &&
                [_project isEqualToString:serverUrl.project]) {
                return YES;
            }
//        }
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
                NSURL *u = [NSURL URLWithString:url];
                _host = [u host];
                NSString *query = [u query];
                if (query != nil) {
                    NSArray *subArray = [query componentsSeparatedByString:@"&"];
                    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
                    if (subArray) {
                        for (int j = 0 ; j < subArray.count; j++) {
                            //在通过=拆分键和值
                            NSArray *dicArray = [subArray[j] componentsSeparatedByString:@"="];
                            //给字典加入元素
                            [tempDic setObject:dicArray[1] forKey:dicArray[0]];
                        }
                        _project = [tempDic objectForKey:@"project"];
                        _token = [tempDic objectForKey:@"token"];
                    }
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
@end
