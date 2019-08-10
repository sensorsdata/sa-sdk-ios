//
//  SANetwork.m
//  SensorsAnalyticsSDK
//
//  Created by 张敏超 on 2019/3/8.
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

#import "SANetwork.h"
#import "SANetwork+URLUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "NSString+HashCode.h"
#import "SAGzipUtility.h"
#import "SALogger.h"
#import "SAJSONUtil.h"

typedef NSURLSessionAuthChallengeDisposition (^SAURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef NSURLSessionAuthChallengeDisposition (^SAURLSessionTaskDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);

@interface SANetwork () <NSURLSessionDelegate, NSURLSessionTaskDelegate>
/// 存储原始的 ServerURL，当修改 DebugMode 为 Off 时，会使用此值去设置 ServerURL
@property (nonatomic, readwrite, strong) NSURL *originServerURL;
/// 网络请求调用结束的 Block 所在的线程
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *cookie;

@property (nonatomic, copy) SAURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
@property (nonatomic, copy) SAURLSessionTaskDidReceiveAuthenticationChallengeBlock taskDidReceiveAuthenticationChallenge;

@end

@implementation SANetwork

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        _securityPolicy = [SASecurityPolicy defaultPolicy];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (instancetype)initWithServerURL:(NSURL *)serverURL {
    self = [super init];
    if (self) {
        _securityPolicy = [SASecurityPolicy defaultPolicy];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        self.serverURL = serverURL;
    }
    return self;
}

#pragma mark - property
- (void)setServerURL:(NSURL *)serverURL {
    _originServerURL = serverURL;
    if (self.debugMode == SensorsAnalyticsDebugOff || serverURL == nil) {
        _serverURL = serverURL;
    } else {
        // 将 Server URI Path 替换成 Debug 模式的 '/debug'
        if (serverURL.lastPathComponent.length > 0) {
            serverURL = [serverURL URLByDeletingLastPathComponent];
        }
        NSURL *url = [serverURL URLByAppendingPathComponent:@"debug"];
        if ([url.host rangeOfString:@"_"].location != NSNotFound) { //包含下划线日志提示
            NSString * referenceURL = @"https://en.wikipedia.org/wiki/Hostname";
            SALog(@"Server url:%@ contains '_'  is not recommend,see details:%@", serverURL.absoluteString, referenceURL);
        }
        _serverURL = url;
    }
}

- (void)setDebugMode:(SensorsAnalyticsDebugMode)debugMode {
    _debugMode = debugMode;
    self.serverURL = _originServerURL;
}

- (NSURLSession *)session {
    @synchronized (self) {
        if (!_session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 30.0;
            config.HTTPShouldUsePipelining = NO;
            _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.operationQueue];
        }
    }
    return _session;
}

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
    _securityPolicy = securityPolicy;
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
// 1. 先完成这一系列Json字符串的拼接
- (NSString *)buildFlushJSONStringWithEvents:(NSArray<NSString *> *)events {
    return [NSString stringWithFormat:@"[%@]", [events componentsJoinedByString:@","]];
}

- (NSURLRequest *)buildFlushRequestWithJSONString:(NSString *)jsonString HTTPMethod:(NSString *)HTTPMethod {
    NSString *postBody;
    @try {
        int gzip = 9; // gzip = 9 表示加密编码
        NSString *b64String = [jsonString copy];
#ifndef SENSORS_ANALYTICS_ENABLE_ENCRYPTION
        // 加密数据已经做过 gzip 压缩和 base64 处理了，就不需要再处理。
        gzip = 1;
        // 使用gzip进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[b64String dataUsingEncoding:NSUTF8StringEncoding]];
        // base64
        b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
#endif

        int hashCode = [b64String sensorsdata_hashCode];
        b64String = [b64String stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        postBody = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, b64String];

    } @catch (NSException *exception) {
        SAError(@"%@ flushByPost format data error: %@", self, exception);
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = HTTPMethod;
    request.HTTPBody = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    // 普通事件请求，使用标准 UserAgent
    [request setValue:@"SensorsAnalytics iOS SDK" forHTTPHeaderField:@"User-Agent"];
    if (self.debugMode == SensorsAnalyticsDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }
    
    //Cookie
    [request setValue:[self cookieWithDecoded:NO] forHTTPHeaderField:@"Cookie"];
    return request;
}

- (NSURL *)buildDebugModeCallbackURLWithParams:(NSDictionary<NSString *, id> *)params {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self.serverURL resolvingAgainstBaseURL:NO];
    NSString *queryString = [SANetwork urlQueryStringWithParams:params];
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
    SAJSONUtil *jsonUtil = [[SAJSONUtil alloc] init];
    NSData *jsonData = [jsonUtil JSONSerializeObject:callData];
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
            SALog(@"URLString is malformed, nil is returned.");
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
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(SAURLSessionTaskCompletionHandler)completionHandler {
    return [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            return completionHandler(nil, nil, error);
        }
        return completionHandler(data, (NSHTTPURLResponse *)response, error);
    }];
}

- (BOOL)flushEvents:(NSArray<NSString *> *)events {
    if (![self isValidServerURL]) {
        SAError(@"serverURL error，Please check the serverURL");
        return NO;
    }
    
    NSString *jsonString = [self buildFlushJSONStringWithEvents:events];
    
    __block BOOL flushSuccess = NO;
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    SAURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            SAError(@"%@", [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"]);
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        
        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger statusCode = response.statusCode;
        NSString *messageDesc = nil;
        if (statusCode >= 200 && statusCode < 300) {
            messageDesc = @"\n【valid message】\n";
        } else {
            messageDesc = @"\n【invalid message】\n";
            if (statusCode >= 300 && self.debugMode != SensorsAnalyticsDebugOff) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                [[SensorsAnalyticsSDK sharedInstance] showDebugModeWarning:errMsg withNoMoreButton:YES];
            }
        }
        // 1、开启 debug 模式，都删除；
        // 2、debugOff 模式下，只有 5xx & 404 & 403 不删，其余均删；
        BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
        flushSuccess = self.debugMode != SensorsAnalyticsDebugOff || successCode;

        SAError(@"==========================================================================");
        @try {
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            SAError(@"%@ %@: %@", self, messageDesc, dict);
        } @catch (NSException *exception) {
            SAError(@"%@: %@", self, exception);
        }
        
        if (statusCode != 200) {
            SAError(@"%@ ret_code: %ld", self, statusCode);
            SAError(@"%@ ret_content: %@", self, urlResponseContent);
        }
        
        dispatch_semaphore_signal(flushSemaphore);
    };
    
    NSURLRequest *request = [self buildFlushRequestWithJSONString:jsonString HTTPMethod:@"POST"];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:handler];
    [task resume];
    
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);
    
    return flushSuccess;
}

- (NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, id> *)params {
    if (![self isValidServerURL]) {
        SAError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURL *url = [self buildDebugModeCallbackURLWithParams:params];
    NSURLRequest *request = [self buildDebugModeCallbackRequestWithURL:url distinctId:distinctId];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            SALog(@"config debugMode CallBack success");
        } else {
            SAError(@"config debugMode CallBack Faild statusCode：%d，url：%@", statusCode, url);
        }
    }];
    [task resume];
    return task;
}

- (NSURLSessionTask *)functionalManagermentConfigWithRemoteConfigURL:(nullable NSURL *)remoteConfigURL version:(NSString *)version completion:(void(^)(BOOL success, NSDictionary<NSString *, id> *config))completion {
    if (![self isValidServerURL]) {
        SAError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURLRequest *request = [self buildFunctionalManagermentConfigRequestWithWithRemoteConfigURL:remoteConfigURL version:version];
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
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
            SAError(@"%@ error: %@", self, e);
            success = NO;
        }
        completion(success, config);
    }];
    [task resume];
    return task;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.sessionDidReceiveAuthenticationChallenge) {
        disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);
    } else {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if (credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.taskDidReceiveAuthenticationChallenge) {
        disposition = self.taskDidReceiveAuthenticationChallenge(session, task, challenge, &credential);
    } else {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                disposition = NSURLSessionAuthChallengeUseCredential;
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

@end

#pragma mark -
@implementation SANetwork (ServerURL)

- (NSString *)host {
    return [SANetwork hostWithURL:self.serverURL] ?: @"";
}

- (NSString *)project {
    return [SANetwork queryItemsWithURL:self.serverURL][@"project"] ?: @"default";
}

- (NSString *)token {
    return [SANetwork queryItemsWithURL:self.serverURL][@"token"] ?: @"";
}

- (BOOL)isSameProjectWithURLString:(NSString *)URLString {
    if (![self isValidServerURL] || URLString.length == 0) {
        return NO;
    }
    BOOL isEqualHost = [self.host isEqualToString:[SANetwork hostWithURLString:URLString]];
    NSString *project = [SANetwork queryItemsWithURLString:URLString][@"project"] ?: @"default";
    BOOL isEqualProject = [self.project isEqualToString:project];
    return isEqualHost && isEqualProject;
}

- (BOOL)isValidServerURL {
    return _serverURL.absoluteString.length > 0;
}

@end

#pragma mark -
@implementation SANetwork (SessionAndTask)

- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.sessionDidReceiveAuthenticationChallenge = block;
}

- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.taskDidReceiveAuthenticationChallenge = block;
}

@end
