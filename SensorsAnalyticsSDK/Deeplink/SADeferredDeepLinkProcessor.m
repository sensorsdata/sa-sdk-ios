//
// SADeferredDeepLinkProcessor.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2022/3/14.
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

#import "SADeferredDeepLinkProcessor.h"
#import "SADeepLinkConstants.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAJSONUtil.h"
#import "SANetwork.h"
#import "SAUserAgent.h"
#import "SANetworkInfoPropertyPlugin.h"
#import "SAConstants+Private.h"

@implementation SADeferredDeepLinkProcessor

- (void)startWithProperties:(NSDictionary *)properties {
    NSString *userAgent = properties[kSARequestPropertyUserAgent];
    if (userAgent.length > 0) {
        NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
        [newProperties removeObjectForKey:kSARequestPropertyUserAgent];
        NSURLRequest *request = [self buildRequest:userAgent properties:newProperties];
        [self requestForDeferredDeepLink:request];
    } else {
        __block typeof(self) weakSelf = self;
        [SAUserAgent loadUserAgentWithCompletion:^(NSString *userAgent) {
            NSURLRequest *request = [weakSelf buildRequest:userAgent properties:properties];
            [weakSelf requestForDeferredDeepLink:request];
        }];
    }
}

- (void)requestForDeferredDeepLink:(NSURLRequest *)request {
    if (!request) {
        return;
    }
    NSTimeInterval start = NSDate.date.timeIntervalSince1970;
    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSTimeInterval interval = (NSDate.date.timeIntervalSince1970 - start);

        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[kSAEventPropertyDuration] = [NSString stringWithFormat:@"%.3f", interval];
        properties[kSAEventPropertyADMatchType] = @"deferred deeplink";

        NSData *deviceInfoData = [[self appInstallSource] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64 = [deviceInfoData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        properties[kSAEventPropertyADDeviceInfo] = base64;

        SADeepLinkObject *obj = [[SADeepLinkObject alloc] init];
        obj.appAwakePassedTime = interval * 1000;
        obj.success = NO;

        NSDictionary *latestChannels;
        NSString *slinkID;

        if (response.statusCode == 200) {
            NSDictionary *result = [SAJSONUtil JSONObjectWithData:data];
            properties[kSAEventPropertyDeepLinkOptions] = result[kSAResponsePropertyParameter];
            properties[kSAEventPropertyADChannel] = result[kSAResponsePropertyADChannel];
            properties[kSAEventPropertyDeepLinkFailReason] = result ? result[kSAResponsePropertyMessage] : @"response is null";
            properties[kSAEventPropertyADSLinkID] = result[kSAResponsePropertySLinkID];
            properties[kSADynamicSlinkEventPropertyTemplateID] = result[kSADynamicSlinkParamTemplateID];
            properties[kSADynamicSlinkEventPropertyType] = result[kSADynamicSlinkParamType];;
            obj.params = result[kSAResponsePropertyParameter];
            obj.adChannels = result[kSAResponsePropertyADChannel];
            obj.success = (result[kSAResponsePropertyCode] && [result[kSAResponsePropertyCode] integerValue] == 0);

            // Result 事件中添加 $utm_* 属性
            [properties addEntriesFromDictionary:[self acquireChannels:result[kSAResponsePropertyChannelParams]]];

            // 解析并并转换为 $latest_utm_content 属性，并添加到后续事件所有事件中
            latestChannels = [self acquireLatestChannels:result[kSAResponsePropertyChannelParams]];
            slinkID = result[kSAResponsePropertySLinkID];
        } else {
            NSString *codeMsg = [NSString stringWithFormat:@"http status code: %@",@(response.statusCode)];
            properties[kSAEventPropertyDeepLinkFailReason] = error.localizedDescription ?: codeMsg;
        }

        // 确保调用客户设置的 completion 是在主线程中
        dispatch_async(dispatch_get_main_queue(), ^{
            SADeepLinkCompletion completion;
            if ([self.delegate respondsToSelector:@selector(sendChannels:latestChannels:isDeferredDeepLink:)]) {
                // 当前方式不需要获取 channels 信息，只需要保存 latestChannels 信息
                completion = [self.delegate sendChannels:nil latestChannels:latestChannels isDeferredDeepLink:YES];
            }
            if (obj.success && !completion) {
                properties[kSAEventPropertyDeepLinkFailReason] = SALocalizedString(@"SADeepLinkCallback");
            }
            [self trackDeepLinkMatchedResult:properties];

            if (!completion) {
                return;
            }

            BOOL jumpSuccess = completion(obj);
            // 只有当请求成功，并且客户跳转页面成功后，触发 $AdAppDeferredDeepLinkJump 事件
            if (!obj.success || !jumpSuccess) {
                return;
            }
            SAPresetEventObject *object = [[SAPresetEventObject alloc] initWithEventId:kSADeferredDeepLinkJumpEvent];
            NSMutableDictionary *jumpProps = [NSMutableDictionary dictionary];
            jumpProps[kSAEventPropertyDeepLinkOptions] = obj.params;
            jumpProps[kSAEventPropertyADSLinkID] = slinkID;
            jumpProps[kSADynamicSlinkEventPropertyTemplateID] = properties[kSADynamicSlinkEventPropertyTemplateID];
            jumpProps[kSADynamicSlinkEventPropertyType] = properties[kSADynamicSlinkEventPropertyType];

            [SensorsAnalyticsSDK.sharedInstance trackEventObject:object properties:jumpProps];

        });
    }];
    [task resume];
}

- (NSURLRequest *)buildRequest:(NSString *)userAgent properties:(NSDictionary *)properties {
    NSString *channelURL = SensorsAnalyticsSDK.sharedInstance.configOptions.customADChannelURL;
    NSURLComponents *components;
    if (channelURL.length > 0) {
        components = [[NSURLComponents alloc] initWithString:channelURL];
    } else {
        components = SensorsAnalyticsSDK.sharedInstance.network.baseURLComponents;
    }

    if (!components) {
        return nil;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSData *data = [[self appInstallSource] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    params[kSARequestPropertyIDs] = base64;
    params[kSARequestPropertyUA] = userAgent;
    params[kSARequestPropertyOS] = @"iOS";
    params[kSARequestPropertyOSVersion] = UIDevice.currentDevice.systemVersion;
    params[kSARequestPropertyModel] = UIDevice.currentDevice.model;
    SANetworkInfoPropertyPlugin *plugin = [[SANetworkInfoPropertyPlugin alloc] init];
    params[kSARequestPropertyNetwork] = [plugin networkTypeString];
    NSInteger timestamp = [@([[NSDate date] timeIntervalSince1970] * 1000) integerValue];
    params[kSARequestPropertyTimestamp] = @(timestamp);
    params[kSARequestPropertyAppID] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[kSARequestPropertyAppVersion] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    params[kSARequestPropertyAppParameter] = [SAJSONUtil stringWithJSONObject:properties];
    params[kSARequestPropertyProject] = SensorsAnalyticsSDK.sharedInstance.network.project;
    components.path = [components.path stringByAppendingPathComponent:@"/slink/ddeeplink"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.timeoutInterval = 60;
    request.HTTPBody = [SAJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end
