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
#import "SensorsAnalyticsSDK.h"
#import "SAConstants+Private.h"

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
        
        SAApplicationStateSerializer *serializer = [[SAApplicationStateSerializer alloc] initWithApplication:[UIApplication sharedApplication] configuration:serializerConfig objectIdentityProvider:objectIdentityProvider];
        
        SAVisualizedSnapshotResponseMessage *snapshotMessage = [SAVisualizedSnapshotResponseMessage message];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *serializedObjects = [serializer objectHierarchyForWindow:UIApplication.sharedApplication.keyWindow];
             snapshotMessage.serializedObjects = serializedObjects;
            
            [serializer screenshotImageForAllWindowWithCompletionHandler:^(UIImage *image) {
                snapshotMessage.screenshot = image;
                [conn sendMessage:snapshotMessage];
            }];
        });
    }];
    
    return operation;
}

@end

#pragma mark -- Snapshot Response

@implementation SAVisualizedSnapshotResponseMessage

+ (instancetype)message {
    return [(SAVisualizedSnapshotResponseMessage *)[self alloc] initWithType:@"snapshot_response"];
}

- (void)setScreenshot:(UIImage *)screenshot {
    id payloadObject = nil;
    id imageHash = nil;
    if (screenshot) {
        NSData *jpegSnapshotImageData = UIImageJPEGRepresentation(screenshot, 0.5);
        if (jpegSnapshotImageData) {
            payloadObject = [jpegSnapshotImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            imageHash = [self imageHashWithData:jpegSnapshotImageData];
        }
    }
    
    _imageHash = imageHash;
    [self setPayloadObject:(payloadObject ?: [NSNull null]) forKey:@"screenshot"];
    [self setPayloadObject:(imageHash ?: [NSNull null]) forKey:@"image_hash"];
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

- (NSString *)imageHashWithData:(NSData *)imageData {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageData.bytes, (uint)imageData.length, result);
    NSString *imageHash = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]];
    return imageHash;
}

@end



