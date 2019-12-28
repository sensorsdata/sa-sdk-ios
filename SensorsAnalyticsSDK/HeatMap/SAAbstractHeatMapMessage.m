//
//  SAAbstractHeatMapMessage.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
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
#import "SAAbstractHeatMapMessage.h"
#import "SensorsAnalyticsSDK.h"
#import "SALogger.h"

@interface SAAbstractHeatMapMessage ()

@property (nonatomic, copy, readwrite) NSString *type;

@end

@implementation SAAbstractHeatMapMessage {
    NSMutableDictionary *_payload;
}

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload {
    return [[self alloc] initWithType:type payload:payload];
}

- (instancetype)initWithType:(NSString *)type {
    return [self initWithType:type payload:@{}];
}

- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload {
    self = [super init];
    if (self) {
        _type = type;
        _payload = [payload mutableCopy];
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

- (NSData *)JSONData:(BOOL)useGzip featuerCode:(NSString *)featureCode {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    [jsonObject setObject:_type forKey:@"type"];
    [jsonObject setObject:@"iOS" forKey:@"os"];
    @try {
        UIViewController *viewController = [[SensorsAnalyticsSDK sharedInstance] currentViewController];
        if (viewController) {
            [jsonObject setObject:NSStringFromClass([viewController class]) forKey:@"screen_name"];
        }
    } @catch (NSException *exception) {
        SAError(@"%@ error: %@", self, exception);
    }
    [jsonObject setObject:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"app_version"];
    [jsonObject setObject:featureCode forKey:@"feature_code"];
    if (useGzip) {
        // 如果使用 GZip 压缩
        NSError *error = nil;
        
        // 1. 序列化 Payload
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[_payload copy] options:0 error:&error];
        NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        // 2. 使用 GZip 进行压缩
        NSData *zippedData = [SAGzipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

        // 3. Base64 Encode
        NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];

        [jsonObject setValue:b64String forKey:@"gzip_payload"];
    } else {
        [jsonObject setValue:[_payload copy] forKey:@"payload"];
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    if (jsonData == nil && error) {
        SAError(@"Failed to serialize test designer message: %@", error);
    }

    return jsonData;
}

- (NSOperation *)responseCommandWithConnection:(SAHeatMapConnection *)connection {
    return nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p type='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.type];
}

@end
