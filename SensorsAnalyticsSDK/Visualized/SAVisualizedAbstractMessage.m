//
//  SAVisualizedAbstractMessage.m
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/4.
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


#import "SAGzipUtility.h"
#import "SAVisualizedAbstractMessage.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "UIViewController+AutoTrack.h"
#import "SAAutoTrackUtils.h"

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
    _payload[key] = object ?: [NSNull null];
}

- (id)payloadObjectForKey:(NSString *)key {
    id object = _payload[key];
    return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSDictionary *)payload {
    return [_payload copy];
}

- (NSData *)JSONData:(BOOL)useGzip featureCode:(NSString *)featureCode {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"type"] = _type;
    jsonObject[@"os"] = @"iOS"; // 操作系统类型
    jsonObject[@"lib"] = @"iOS"; // SDK 类型

    @try {
        UIViewController<SAAutoTrackViewControllerProperty> *viewController = (UIViewController<SAAutoTrackViewControllerProperty> *)[SAAutoTrackUtils currentViewController];
        if (viewController) {
            jsonObject[@"screen_name"] = viewController.sensorsdata_screenName;
            jsonObject[@"title"] = viewController.sensorsdata_title;
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }

    jsonObject[@"app_version"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    jsonObject[@"feature_code"] = featureCode;

    if (_payload[@"serialized_objects"] && [_payload[@"serialized_objects"] isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *serializedBbjects = [NSMutableDictionary dictionaryWithDictionary:_payload[@"serialized_objects"]];
        NSNumber *isContainWebview = serializedBbjects[@"is_webview"];
        [serializedBbjects removeObjectForKey:@"is_webview"];
        jsonObject[@"is_webview"] = isContainWebview;
    }

    // SDK 版本号
    jsonObject[@"lib_version"] = SensorsAnalyticsSDK.sharedInstance.libVersion;

    if (useGzip) {
        // 如果使用 GZip 压缩
        NSError *error = nil;

        // 1. 序列化 Payload
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[_payload copy] options:0 error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        // 2. 使用 GZip 进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

        // 3. Base64 Encode
        NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];

        jsonObject[@"gzip_payload"] = b64String;
    } else {
        jsonObject[@"payload"] = [_payload copy];
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    if (!jsonData && error) {
        SALogError(@"Failed to serialize test designer message: %@", error);
    }

    return jsonData;
}

- (NSOperation *)responseCommandWithConnection:(SAVisualizedConnection *)connection {
    return nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p type='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.type];
}

@end
