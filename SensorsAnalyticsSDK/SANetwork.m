//
//  SANetwork.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/3/8.
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

#import "SANetwork.h"
#import "SAURLUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SALog.h"
#import "SAJSONUtil.h"
#import "SAHTTPSession.h"

@interface SANetwork ()

@property (nonatomic, copy) NSString *cookie;

@end

@implementation SANetwork

#pragma mark - property
- (void)setSecurityPolicy:(SASecurityPolicy *)securityPolicy {
    if (securityPolicy.SSLPinningMode != SASSLPinningModeNone && ![self.serverURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case SASSLPinningModeNone:
                pinningMode = @"SASSLPinningModeNone";
                break;
            case SASSLPinningModeCertificate:
                pinningMode = @"SASSLPinningModeCertificate";
                break;
            case SASSLPinningModePublicKey:
                pinningMode = @"SASSLPinningModePublicKey";
                break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
    SAHTTPSession.sharedInstance.securityPolicy = securityPolicy;
}

- (SASecurityPolicy *)securityPolicy {
    return SAHTTPSession.sharedInstance.securityPolicy;
}

#pragma mark - cookie
- (void)setCookie:(NSString *)cookie isEncoded:(BOOL)encoded {
    if (encoded) {
        _cookie = [cookie stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    } else {
        _cookie = cookie;
    }
}

- (NSString *)cookieWithDecoded:(BOOL)isDecoded {
    return isDecoded ? _cookie.stringByRemovingPercentEncoding : _cookie;
}

#pragma mark -

#pragma mark - build

- (NSURL *)buildDebugModeCallbackURLWithParams:(NSDictionary<NSString *, id> *)params {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self.serverURL resolvingAgainstBaseURL:NO];
    NSString *queryString = [SAURLUtils urlQueryStringWithParams:params];
    if (urlComponents.query.length) {
        urlComponents.query = [NSString stringWithFormat:@"%@&%@", urlComponents.query, queryString];
    } else {
        urlComponents.query = queryString;
    }
    return urlComponents.URL;
}

- (NSURLRequest *)buildDebugModeCallbackRequestWithURL:(NSURL *)url distinctId:(NSString *)distinctId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *callData = @{@"distinct_id": distinctId};
    NSData *jsonData = [SAJSONUtil JSONSerializeObject:callData];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSURLRequest *)buildFunctionalManagermentConfigRequestWithWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version {

    NSURLComponents *urlComponets = nil;
    if (remoteConfigURL) {
        urlComponets = [NSURLComponents componentsWithURL:remoteConfigURL resolvingAgainstBaseURL:YES];
    }
    if (!urlComponets.host) {
        NSURL *url = self.serverURL.lastPathComponent.length > 0 ? [self.serverURL URLByDeletingLastPathComponent] : self.serverURL;
        urlComponets = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        if (urlComponets == nil) {
            SALogError(@"URLString is malformed, nil is returned.");
            return nil;
        }
        urlComponets.query = nil;
        urlComponets.path = [urlComponets.path stringByAppendingPathComponent:@"/config/iOS.conf"];
    }

    if (version.length) {
        urlComponets.query = [NSString stringWithFormat:@"v=%@", version];
    }
    return [NSURLRequest requestWithURL:urlComponets.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
}

#pragma mark - request

- (NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, id> *)params {
    if (![self isValidServerURL]) {
        SALogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURL *url = [self buildDebugModeCallbackURLWithParams:params];
    NSURLRequest *request = [self buildDebugModeCallbackRequestWithURL:url distinctId:distinctId];

    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            SALogDebug(@"config debugMode CallBack success");
        } else {
            SALogError(@"config debugMode CallBack Faild statusCode：%ld，url：%@", statusCode, url);
        }
    }];
    [task resume];
    return task;
}

- (NSURLSessionTask *)functionalManagermentConfigWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion {
    if (![self isValidServerURL]) {
        SALogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURLRequest *request = [self buildFunctionalManagermentConfigRequestWithWithRemoteConfigURL:remoteConfigURL version:version];
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) {
            return ;
        }
        NSInteger statusCode = response.statusCode;
        BOOL success = statusCode == 200 || statusCode == 304;
        NSDictionary<NSString *, id> *config = nil;
        @try{
            if (statusCode == 200 && data.length) {
                config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            }
        } @catch (NSException *e) {
            SALogError(@"%@ error: %@", self, e);
            success = NO;
        }
        completion(success, config);
    }];
    [task resume];
    return task;
}

@end

#pragma mark -
@implementation SANetwork (ServerURL)

- (NSURL *)serverURL {
    NSURL *serverURL = [NSURL URLWithString:[SensorsAnalyticsSDK sharedInstance].configOptions.serverURL];
    if (self.debugMode == SensorsAnalyticsDebugOff || serverURL == nil) {
        return serverURL;
    }
    NSURL *url = serverURL;
    // 将 Server URI Path 替换成 Debug 模式的 '/debug'
    if (serverURL.lastPathComponent.length > 0) {
        url = [serverURL URLByDeletingLastPathComponent];
    }
    url = [url URLByAppendingPathComponent:@"debug"];
    if (url.host && [url.host rangeOfString:@"_"].location != NSNotFound) { //包含下划线日志提示
        NSString *referenceURL = @"https://en.wikipedia.org/wiki/Hostname";
        SALogWarn(@"Server url:%@ contains '_'  is not recommend,see details:%@", serverURL, referenceURL);
    }
    return url;
}

- (NSString *)host {
    return [SAURLUtils hostWithURL:self.serverURL] ?: @"";
}

- (NSString *)project {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"project"] ?: @"default";
}

- (NSString *)token {
    return [SAURLUtils queryItemsWithURL:self.serverURL][@"token"] ?: @"";
}

- (BOOL)isSameProjectWithURLString:(NSString *)URLString {
    if (![self isValidServerURL] || URLString.length == 0) {
        return NO;
    }
    BOOL isEqualHost = [self.host isEqualToString:[SAURLUtils hostWithURLString:URLString]];
    NSString *project = [SAURLUtils queryItemsWithURLString:URLString][@"project"] ?: @"default";
    BOOL isEqualProject = [self.project isEqualToString:project];
    return isEqualHost && isEqualProject;
}

- (BOOL)isValidServerURL {
    return self.serverURL.absoluteString.length > 0;
}

@end
