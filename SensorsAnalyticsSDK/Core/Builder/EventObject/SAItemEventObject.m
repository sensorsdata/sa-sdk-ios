//
// SAItemEventObject.m
// SensorsAnalyticsSDK
//
// Created by 张敏超 on 2021/11/3.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAItemEventObject.h"
#import "SAConstants+Private.h"

static NSString * const kSAEventItemType = @"item_type";
static NSString * const kSAEventItemID = @"item_id";

@implementation SAItemEventObject

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID {
    self = [super init];
    if (self) {
        self.type = [SAItemEventObject eventTypeWithType:type];
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
    eventInfo[kSAEventProperties] = (self.type & SAEventTypeItemDelete) ? nil : self.properties;
    eventInfo[kSAEventItemType] = self.itemType;
    eventInfo[kSAEventItemID] = self.itemID;
    eventInfo[kSAEventType] = [SABaseEventObject typeWithEventType:self.type];
    eventInfo[kSAEventTime] = @(self.time);
    eventInfo[kSAEventLib] = [self.lib jsonObject];
    eventInfo[kSAEventProject] = self.project;
    eventInfo[kSAEventToken] = self.token;
    return eventInfo;
}

@end
