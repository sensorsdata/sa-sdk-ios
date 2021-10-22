//
//  SAVisualizedSnapshotMessage.m
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


#import <CommonCrypto/CommonDigest.h>
#import "SAVisualizedSnapshotMessage.h"
#import "SAApplicationStateSerializer.h"
#import "SAObjectIdentityProvider.h"
#import "SAObjectSerializerConfig.h"
#import "SAVisualizedConnection.h"
#import "SAConstants+Private.h"
#import "SAVisualizedManager.h"
#import "SAVisualizedObjectSerializerManager.h"
#import "SACommonUtility.h"

#pragma mark -- Snapshot Request

NSString * const SAVisualizedSnapshotRequestMessageType = @"snapshot_request";

static NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";

@implementation SAVisualizedSnapshotRequestMessage

+ (instancetype)message {
    return [(SAVisualizedSnapshotRequestMessage *)[self alloc] initWithType:SAVisualizedSnapshotRequestMessageType];
}

- (SAObjectSerializerConfig *)configuration {
    NSDictionary *config = [self payloadObjectForKey:@"config"];
    return config ? [[SAObjectSerializerConfig alloc] initWithDictionary:config] : nil;
}


// 构建页面信息，包括截图和元素数据
- (NSOperation *)responseCommandWithConnection:(SAVisualizedConnection *)connection {
    SAObjectSerializerConfig *serializerConfig = self.configuration;

    __weak SAVisualizedConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong SAVisualizedConnection *conn = weak_connection;

        // Get the object identity provider from the connection's session store or create one if there is none already.
        SAObjectIdentityProvider *objectIdentityProvider = [[SAObjectIdentityProvider alloc] init];

        SAApplicationStateSerializer *serializer = [[SAApplicationStateSerializer alloc] initWithConfiguration:serializerConfig objectIdentityProvider:objectIdentityProvider];

        SAVisualizedSnapshotResponseMessage *snapshotMessage = [SAVisualizedSnapshotResponseMessage message];

        dispatch_async(dispatch_get_main_queue(), ^{
            [serializer screenshotImageForAllWindowWithCompletionHandler:^(UIImage *image) {
                // 添加待校验事件
                snapshotMessage.debugEvents = SAVisualizedManager.defaultManager.eventCheck.eventCheckResult;
                // 清除事件缓存
                [SAVisualizedManager.defaultManager.eventCheck cleanEventCheckResult];

                // 添加诊断信息
                snapshotMessage.logInfos = SAVisualizedManager.defaultManager.visualPropertiesTracker.logInfos;

                // 最后构建截图，并设置 imageHash
                snapshotMessage.screenshot = image;

                // payloadHash 不变即截图相同，页面不变，则不再解析页面元素信息
                if ([[SAVisualizedObjectSerializerManager sharedInstance].lastPayloadHash isEqualToString:snapshotMessage.payloadHash]) {
                    [conn sendMessage:[SAVisualizedSnapshotResponseMessage message]];

                    // 不包含页面元素等数据，只发送页面基本信息，重置 payloadHash 为截图 hash
                    [[SAVisualizedObjectSerializerManager sharedInstance] resetLastPayloadHash:snapshotMessage.originImageHash];
                } else {
                    // 清空页面配置信息
                    [[SAVisualizedObjectSerializerManager sharedInstance] resetObjectSerializer];

                    // 解析页面信息
                    NSDictionary *serializedObjects = [serializer objectHierarchyForRootObject];
                    snapshotMessage.serializedObjects = serializedObjects;
                    [conn sendMessage:snapshotMessage];

                    // 重置 payload hash 信息
                    [[SAVisualizedObjectSerializerManager sharedInstance] resetLastPayloadHash:snapshotMessage.payloadHash];
                }
            }];
        });
    }];

    return operation;
}

@end

#pragma mark -- Snapshot Response
@interface SAVisualizedSnapshotResponseMessage()
@property (nonatomic, copy, readwrite) NSString *originImageHash;
@end

@implementation SAVisualizedSnapshotResponseMessage

+ (instancetype)message {
    return [(SAVisualizedSnapshotResponseMessage *)[self alloc] initWithType:@"snapshot_response"];
}

- (void)setScreenshot:(UIImage *)screenshot {
    id payloadObject = nil;
    NSString *imageHash = nil;
    if (screenshot) {
        NSData *jpegSnapshotImageData = UIImageJPEGRepresentation(screenshot, 0.5);
        if (jpegSnapshotImageData) {
            payloadObject = [jpegSnapshotImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            imageHash = [SACommonUtility hashStringWithData:jpegSnapshotImageData];

            // 保留原始图片 hash 值
            self.originImageHash = imageHash;
        }
    }

    // 如果包含其他数据，拼接到 imageHash，防止前端数据未刷新
    NSString *payloadHash = [[SAVisualizedObjectSerializerManager sharedInstance] fetchPayloadHashWithImageHash:imageHash];

    self.payloadHash = payloadHash;
    [self setPayloadObject:payloadObject forKey:@"screenshot"];
    [self setPayloadObject:payloadHash forKey:@"image_hash"];
}

- (void)setDebugEvents:(NSArray<NSDictionary *> *)debugEvents {
    if (debugEvents.count == 0) {
        return;
    }
    
    // 更新 imageHash
    [[SAVisualizedObjectSerializerManager sharedInstance] refreshPayloadHashWithData:debugEvents];
    
    [self setPayloadObject:debugEvents forKey:@"event_debug"];
}

- (void)setLogInfos:(NSArray<NSDictionary *> *)logInfos {
    if (logInfos.count == 0) {
        return;
    }
    // 更新 imageHash
    [[SAVisualizedObjectSerializerManager sharedInstance] refreshPayloadHashWithData:logInfos];

    [self setPayloadObject:logInfos forKey:@"log_info"];
}

- (UIImage *)screenshot {
    NSString *base64Image = [self payloadObjectForKey:@"screenshot"];
    NSData *imageData =[[base64Image dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

- (void)setSerializedObjects:(NSDictionary *)serializedObjects {
    [self setPayloadObject:serializedObjects forKey:@"serialized_objects"];
}

- (NSDictionary *)serializedObjects {
    return [self payloadObjectForKey:@"serialized_objects"];
}

@end



