//
// SAReferrerManager.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAReferrerManager : NSObject

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL isClearReferrer;

@property (atomic, copy, readonly) NSDictionary *referrerProperties;
@property (atomic, copy, readonly) NSString *referrerURL;
@property (nonatomic, copy, readonly) NSString *referrerTitle;

+ (instancetype)sharedInstance;

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties;

- (void)clearReferrer;

@end

NS_ASSUME_NONNULL_END
