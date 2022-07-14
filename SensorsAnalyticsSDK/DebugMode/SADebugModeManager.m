//
// SADebugModeManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/11/20.
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

#import "SADebugModeManager.h"
#import "SAModuleManager.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAAlertController.h"
#import "SAURLUtils.h"
#import "SAJSONUtil.h"
#import "SANetwork.h"
#import "SALog.h"
#import "SAApplication.h"
#import "SAConstants+Private.h"

@interface SADebugModeManager ()

@property (nonatomic) UInt8 debugAlertViewHasShownNumber;

@end

@implementation SADebugModeManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SADebugModeManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SADebugModeManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showDebugAlertView = YES;
        _debugAlertViewHasShownNumber = 0;
    }
    return self;
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions {
    if ([SAApplication isAppExtension]) {
        configOptions.debugMode = SensorsAnalyticsDebugOff;
    }
    _configOptions = configOptions;
    self.enable = configOptions.debugMode != SensorsAnalyticsDebugOff;
}

- (BOOL)isEnable {
    if ([SAApplication isAppExtension]) {
        return NO;
    }
    return self.configOptions.debugMode != SensorsAnalyticsDebugOff;
}

#pragma mark - SAOpenURLProtocol

- (BOOL)canHandleURL:(nonnull NSURL *)url {
    return [url.host isEqualToString:@"debugmode"];
}

- (BOOL)handleURL:(nonnull NSURL *)url {
    // url query 解析
    NSDictionary *paramDic = [SAURLUtils queryItemsWithURL:url];

    //如果没传 info_id，视为伪造二维码，不做处理
    if (paramDic.allKeys.count && [paramDic.allKeys containsObject:@"info_id"]) {
        [self showDebugModeAlertWithParams:paramDic];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - SADebugModeModuleProtocol

- (void)showDebugModeWarning:(NSString *)message {
    [self showDebugModeWarning:message withNoMoreButton:YES];
}

#pragma mark - Private

- (void)showDebugModeAlertWithParams:(NSDictionary<NSString *, NSString *> *)params {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_block_t alterViewBlock = ^{

            NSString *alterViewMessage = @"";
            if (self.configOptions.debugMode == SensorsAnalyticsDebugAndTrack) {
                alterViewMessage = SALocalizedString(@"SADebugAndTrackModeTurnedOn");
            } else if (self.configOptions.debugMode == SensorsAnalyticsDebugOnly) {
                alterViewMessage = SALocalizedString(@"SADebugOnlyModeTurnedOn");
            } else {
                alterViewMessage = SALocalizedString(@"SADebugModeTurnedOff");
            }
            SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:@"" message:alterViewMessage preferredStyle:SAAlertControllerStyleAlert];
            [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleCancel handler:nil];
            [alertController show];
        };

        NSString *alertTitle = SALocalizedString(@"SADebugMode");
        NSString *alertMessage = @"";
        if (self.configOptions.debugMode == SensorsAnalyticsDebugAndTrack) {
            alertMessage = SALocalizedString(@"SADebugCurrentlyInDebugAndTrack");
        } else if (self.configOptions.debugMode == SensorsAnalyticsDebugOnly) {
            alertMessage = SALocalizedString(@"SADebugCurrentlyInDebugOnly");
        } else {
            alertMessage = SALocalizedString(@"SADebugOff");
        }
        SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];
        void(^handler)(SensorsAnalyticsDebugMode) = ^(SensorsAnalyticsDebugMode debugMode) {
            self.configOptions.debugMode = debugMode;
            alterViewBlock();
            [self debugModeCallbackWithDistinctId:[SensorsAnalyticsSDK sharedInstance].distinctId params:params];
        };
        [alertController addActionWithTitle:SALocalizedString(@"SADebugAndTrack") style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
            handler(SensorsAnalyticsDebugAndTrack);
        }];
        [alertController addActionWithTitle:SALocalizedString(@"SADebugOnly") style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
            handler(SensorsAnalyticsDebugOnly);
        }];
        [alertController addActionWithTitle:SALocalizedString(@"SAAlertCancel") style:SAAlertActionStyleCancel handler:nil];
        [alertController show];
    });
}

- (NSString *)debugModeToString:(SensorsAnalyticsDebugMode)debugMode {
    NSString *modeStr = nil;
    switch (debugMode) {
        case SensorsAnalyticsDebugOff:
            modeStr = @"DebugOff";
            break;
        case SensorsAnalyticsDebugAndTrack:
            modeStr = @"DebugAndTrack";
            break;
        case SensorsAnalyticsDebugOnly:
            modeStr = @"DebugOnly";
            break;
        default:
            modeStr = @"Unknown";
            break;
    }
    return modeStr;
}

- (void)showDebugModeWarning:(NSString *)message withNoMoreButton:(BOOL)showNoMore {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SAModuleManager.sharedInstance isDisableSDK]) {
            return;
        }

        if (self.configOptions.debugMode == SensorsAnalyticsDebugOff) {
            return;
        }

        if (!self.showDebugAlertView) {
            return;
        }

        if (self.debugAlertViewHasShownNumber >= 3) {
            return;
        }
        self.debugAlertViewHasShownNumber += 1;
        NSString *alertTitle = SALocalizedString(@"SADebugNotes");
        SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:message preferredStyle:SAAlertControllerStyleAlert];
        [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleCancel handler:^(SAAlertAction * _Nonnull action) {
            self.debugAlertViewHasShownNumber -= 1;
        }];
        if (showNoMore) {
            [alertController addActionWithTitle:SALocalizedString(@"SAAlertNotRemind") style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
                self.showDebugAlertView = NO;
            }];
        }
        [alertController show];
    });
}

- (NSURL *)serverURL {
    return [SensorsAnalyticsSDK sharedInstance].network.serverURL;
}

#pragma mark - Request

- (NSURL *)buildDebugModeCallbackURLWithParams:(NSDictionary<NSString *, NSString *> *)params {
    NSURLComponents *urlComponents = nil;
    NSString *sfPushCallbackUrl = params[@"sf_push_distinct_id"];
    NSString *infoId = params[@"info_id"];
    NSString *project = params[@"project"];
    if (sfPushCallbackUrl.length > 0 && infoId.length > 0 && project.length > 0) {
        NSURL *url = [NSURL URLWithString:sfPushCallbackUrl];
        urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        urlComponents.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"project" value:project], [[NSURLQueryItem alloc] initWithName:@"info_id" value:infoId]];
        return urlComponents.URL;
    }
    urlComponents = [NSURLComponents componentsWithURL:self.serverURL resolvingAgainstBaseURL:NO];
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
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *callData = @{@"distinct_id": distinctId};
    NSString *jsonString = [SAJSONUtil stringWithJSONObject:callData];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

    return request;
}

- (NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, NSString *> *)params {
    if (self.serverURL.absoluteString.length == 0) {
        SALogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURL *url = [self buildDebugModeCallbackURLWithParams:params];
    if (!url) {
        SALogError(@"callback url in debug mode was nil");
        return nil;
    }

    NSURLRequest *request = [self buildDebugModeCallbackRequestWithURL:url distinctId:distinctId];

    NSURLSessionDataTask *task = [SAHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            SALogDebug(@"config debugMode CallBack success");
        } else {
            SALogError(@"config debugMode CallBack Faild statusCode：%ld，url：%@", (long)statusCode, url);
        }
    }];
    [task resume];
    return task;
}

@end
