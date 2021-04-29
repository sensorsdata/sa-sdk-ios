//
//  SAVisualizedMessage.h
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

#import <Foundation/Foundation.h>

@class SAVisualizedConnection;

@protocol SAVisualizedMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;

- (id)payloadObjectForKey:(NSString *)key;

- (void)removePayloadObjectForKey:(NSString *)key;

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode;

@optional
- (NSOperation *)responseCommandWithConnection:(SAVisualizedConnection *)connection;

@end
