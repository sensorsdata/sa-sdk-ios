//
// SAVisualizedAbstractMessage.m
// SensorsAnalyticsSDK
//
// Created by 向作为 on 2018/9/4.
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


#import "SAGzipUtility.h"
#import "SAVisualizedAbstractMessage.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "UIViewController+AutoTrack.h"
#import "SAAutoTrackUtils.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SAConstants+Private.h"
#import "SAVisualizedUtils.h"
#import "SAJSONUtil.h"
#import "SAVisualizedManager.h"

@interface SAVisualizedAbstractMessage ()

@property (nonatomic, copy, readwrite) NSString *type;

@end

@implementation SAVisualizedAbstractMessage {
    NSMutableDictionary *_payload;
}

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload {
    return [[self alloc] initWithType:type payload:payload];
}

- (instancetype)initWithType:(NSString *)type {
    return [self initWithType:type payload:nil];
}

- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload {
    self = [super init];
    if (self) {
        _type = type;
        if (payload) {
             _payload = [payload mutableCopy];
        } else {
            _payload = [NSMutableDictionary dictionary];
        }
    }

    return self;
}

- (void)setPayloadObject:(id)object forKey:(NSString *)key {
    _payload[key] = object;
}

- (id)payloadObjectForKey:(NSString *)key {
    id object = _payload[key];
    return object;
}

- (void)removePayloadObjectForKey:(NSString *)key {
    if (!key) {
        return;
    }
    [_payload removeObjectForKey:key];
}

- (NSDictionary *)payload {
    return [_payload copy];
}

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"type"] = _type;
    jsonObject[@"os"] = @"iOS"; // 操作系统类型
    jsonObject[@"lib"] = @"iOS"; // SDK 类型

    SAVisualizedObjectSerializerManager *serializerManager = [SAVisualizedObjectSerializerManager sharedInstance];
    NSString *screenName = nil;
    NSString *pageName = nil;
    NSString *title = nil;

    @try {
        // 获取当前页面
        UIViewController *currentViewController = serializerManager.lastViewScreenController;
        if (!currentViewController) {
            currentViewController = [SAAutoTrackUtils currentViewController];
        }

        // 解析页面信息
        NSDictionary *autoTrackScreenProperties = [SAAutoTrackUtils propertiesWithViewController:currentViewController];
        screenName = autoTrackScreenProperties[kSAEventPropertyScreenName];
        pageName = autoTrackScreenProperties[kSAEventPropertyScreenName];
        title = autoTrackScreenProperties[kSAEventPropertyTitle];

        // 获取 RN 页面信息
        NSDictionary <NSString *, NSString *> *RNScreenInfo = [SAVisualizedUtils currentRNScreenVisualizeProperties];
        if (RNScreenInfo[kSAEventPropertyScreenName]) {
            pageName = RNScreenInfo[kSAEventPropertyScreenName];
            screenName = RNScreenInfo[kSAEventPropertyScreenName];
            title = RNScreenInfo[kSAEventPropertyTitle];
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }

    jsonObject[@"page_name"] = pageName;
    jsonObject[@"screen_name"] = screenName;
    jsonObject[@"title"] = title;
    jsonObject[@"app_version"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    jsonObject[@"feature_code"] = featureCode;
    jsonObject[@"is_webview"] = @(serializerManager.isContainWebView);
    // 增加 appId
    jsonObject[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];

    // 上传全埋点配置开启状态
    NSMutableArray<NSString *>* autotrackOptions = [NSMutableArray array];
    SensorsAnalyticsAutoTrackEventType eventType = SensorsAnalyticsSDK.sharedInstance.configOptions.autoTrackEventType;
    if (eventType &  SensorsAnalyticsEventTypeAppClick) {
        [autotrackOptions addObject:kSAEventNameAppClick];
    }
    if (eventType &  SensorsAnalyticsEventTypeAppViewScreen) {
        [autotrackOptions addObject:kSAEventNameAppViewScreen];
    }
    jsonObject[@"app_autotrack"] = autotrackOptions;

    // 自定义属性开关状态
        jsonObject[@"app_enablevisualizedproperties"] = @(SensorsAnalyticsSDK.sharedInstance.configOptions.enableVisualizedProperties);


    // 添加前端弹框信息
    if (serializerManager.alertInfos.count > 0) {
        jsonObject[@"app_alert_infos"] = [serializerManager.alertInfos copy];
    }
    
    // H5 页面信息
    if (serializerManager.webPageInfo) {
        SAVisualizedWebPageInfo *webPageInfo = serializerManager.webPageInfo;
        jsonObject[@"h5_url"] = webPageInfo.url;
        jsonObject[@"h5_title"] = webPageInfo.title;
        jsonObject[@"web_lib_version"] = webPageInfo.webLibVersion;
    }
    
    // SDK 版本号
    jsonObject[@"lib_version"] = SensorsAnalyticsSDK.sharedInstance.libVersion;
    // 可视化全埋点配置版本号
    jsonObject[@"config_version"] = [SAVisualizedManager defaultManager].configSources.configVersion;

    if (_payload.count == 0) {
        return [SAJSONUtil dataWithJSONObject:jsonObject];
    }
    // 如果使用 GZip 压缩
    // 1. 序列化 Payload
    NSData *jsonData = [SAJSONUtil dataWithJSONObject:_payload];
    
    // 2. 使用 GZip 进行压缩
    NSData *zippedData = [SAGzipUtility gzipData:jsonData];
    
    // 3. Base64 Encode
    NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    jsonObject[@"gzip_payload"] = b64String;
    
    return [SAJSONUtil dataWithJSONObject:jsonObject];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p type='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.type];
}

@end
