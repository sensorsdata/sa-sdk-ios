//
// SAObject+SAConfigOptions.h
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/30.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SADatabase.h"
#import "SAEventFlush.h"
#import "SAEventTracker.h"
#import "SAConstants.h"
#import "SADataEncryptBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface SADatabase (SAConfigOptions)

@property (nonatomic, assign, readonly) NSUInteger maxCacheSize;

@end


#pragma mark -

@interface SAEventFlush (SAConfigOptions)

@property (nonatomic, readonly) BOOL isDebugMode;

@property (nonatomic, strong, readonly) NSURL *serverURL;

@property (nonatomic, readonly) BOOL flushBeforeEnterBackground;

@property (nonatomic, readonly) BOOL enableEncrypt;

@property (nonatomic, copy, readonly) NSString *cookie;

@end


#pragma mark -

@interface SAEventTracker (SAConfigOptions)

@property (nonatomic, readonly) BOOL isDebugMode;

@property (nonatomic, readonly) SensorsAnalyticsNetworkType networkTypePolicy;

@property (nonatomic, readonly) NSInteger flushBulkSize;

@property (nonatomic, readonly) BOOL enableEncrypt;
@property (nonatomic, strong, readonly) SADataEncryptBuilder *encryptBuilder;

@end

NS_ASSUME_NONNULL_END
