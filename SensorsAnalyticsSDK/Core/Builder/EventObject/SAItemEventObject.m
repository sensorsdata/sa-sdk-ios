//
// SAItemEventObject.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAItemEventObject.h"
#import "SAConstants+Private.h"

static NSString * const kSAEventItemType = @"item_type";
static NSString * const kSAEventItemID = @"item_id";

NSString * const kSAEventItemSet = @"item_set";
NSString * const kSAEventItemDelete = @"item_delete";

@implementation SAItemEventObject

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID {
    self = [super init];
    if (self) {
        self.type = type;
        _itemType = itemType;
        _itemID = itemID;
    }
    return self;
}

- (void)validateEventWithError:(NSError **)error {
    [SAValidator validKey:self.itemType error:error];
    if (*error && (*error).code != SAValidatorErrorOverflow) {
        self.itemType = nil;
    }

    if (![self.itemID isKindOfClass:[NSString class]]) {
        *error = SAPropertyError(SAValidatorErrorNotString, @"Item_id must be a string");
        self.itemID = nil;
        return;
    }
    if (self.itemID.length > kSAPropertyValueMaxLength) {
        *error = SAPropertyError(SAValidatorErrorOverflow, @"%@'s length is longer than %ld", self.itemID, kSAPropertyValueMaxLength);
        return;
    }
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[kSAEventProperties] = [self.type isEqualToString:kSAEventItemDelete] ? nil : self.properties;
    eventInfo[kSAEventItemType] = self.itemType;
    eventInfo[kSAEventItemID] = self.itemID;
    eventInfo[kSAEventType] = self.type;
    eventInfo[kSAEventTime] = @(self.timeStamp);
    eventInfo[kSAEventLib] = [self.lib jsonObject];
    eventInfo[kSAEventProject] = self.project;
    eventInfo[kSAEventToken] = self.token;
    return eventInfo;
}

@end
