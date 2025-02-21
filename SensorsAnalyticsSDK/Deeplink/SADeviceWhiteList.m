//
// SADeviceWhiteList.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/7/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADeviceWhiteList.h"
#import "SAAlertController.h"
#import "SAURLUtils.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAJSONUtil.h"
#import "SAIdentifier.h"
#import "SAConstants+Private.h"


static NSString * const kSADeviceWhiteListHost = @"adsScanDeviceInfo";
static NSString * const kSADeviceWhiteListQueryParamProjectName = @"project";
static NSString * const kSADeviceWhiteListQueryParamInfoId = @"info_id";
static NSString * const kSADeviceWhiteListQueryParamDeviceType = @"device_type";
static NSString * const kSADeviceWhiteListQueryParamApiUrl = @"apiurl";

@implementation SADeviceWhiteList

- (BOOL)canHandleURL:(NSURL *)url {
    return [url.host isEqualToString:kSADeviceWhiteListHost];
}

- (BOOL)handleURL:(NSURL *)url {
    NSDictionary *query = [SAURLUtils decodeQueryItemsWithURL:url];
    if (!query) {
        return NO;
    }
    NSString *projectName = query[kSADeviceWhiteListQueryParamProjectName];
    if (![projectName isEqualToString:[SensorsAnalyticsSDK sdkInstance].network.project]) {
        [self showAlertWithMessage:SALocalizedString(@"SADeviceWhiteListMessageProject")];
        return NO;
    }
    NSString *deviceType = query[kSADeviceWhiteListQueryParamDeviceType];
    //1 iOS，2 Android
    if (![deviceType isEqualToString:@"1"]) {
        [self showAlertWithMessage:SALocalizedString(@"SADeviceWhiteListMessageDeviceType")];
        return NO;
    }
    NSString *apiUrlString = query[kSADeviceWhiteListQueryParamApiUrl];
    if (!apiUrlString) {
        return NO;
    }
    NSURL *apiUrl = [NSURL URLWithString:apiUrlString];
    if (!apiUrl) {
        return NO;
    }

    NSString *infoId = query[kSADeviceWhiteListQueryParamInfoId];
    NSDictionary *params = @{kSADeviceWhiteListQueryParamInfoId: infoId,
                             kSADeviceWhiteListQueryParamDeviceType:@"1",
                             @"project_name":projectName,
                             @"ios_idfa":[SAIdentifier idfa] ? : @"",
                             @"ios_idfv": [SAIdentifier idfv] ? : @""};
    [self addWhiteListWithUrl:apiUrl params:params];
    return YES;
}

- (void)showAlertWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        SAAlertController *alert = [[SAAlertController alloc] initWithTitle:SALocalizedString(@"SADeviceWhiteListTitle") message:message preferredStyle:SAAlertControllerStyleAlert];
        [alert addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleDefault handler:nil];
        [alert show];
    });
}

- (void)addWhiteListWithUrl:(NSURL *)url params:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    request.HTTPBody = [SAJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[SAHTTPSession sharedInstance] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        //HTTP Status 200 and code 0
        if (response.statusCode == 200) {
            NSDictionary *result = [SAJSONUtil JSONObjectWithData:data];
            if ([result isKindOfClass:[NSDictionary class]] &&
                [result[@"code"] isKindOfClass:[NSNumber class]] &&
                [result[@"code"] integerValue] == 0) {
                [self showAlertWithMessage:SALocalizedString(@"SADeviceWhiteListMessageRequestSuccess")];
                return;
            }
        }
        [self showAlertWithMessage:SALocalizedString(@"SADeviceWhiteListMessageRequestFailure")];
    }];
    [task resume];
}

@end
