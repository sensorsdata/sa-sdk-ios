//
// SAItemEventObject.h
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2021/11/3.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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
#import "SABaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSAEventItemSet;
extern NSString * const kSAEventItemDelete;

@interface SAItemEventObject : SABaseEventObject

@property (nonatomic, copy, nullable) NSString *itemType;
@property (nonatomic, copy, nullable) NSString *itemID;

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID;

@end

NS_ASSUME_NONNULL_END
