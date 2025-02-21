//
// SensorsAnalyticsSDK+SAAppExtension.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/5/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SensorsAnalyticsSDK+SAAppExtension.h"
#import "SALog.h"
#import "SAAppExtensionDataManager.h"
#import "SAConstants+Private.h"

@implementation SensorsAnalyticsSDK (SAAppExtension)

- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion {
    @try {
        if (groupIdentifier == nil || [groupIdentifier isEqualToString:@""]) {
            return;
        }
        NSArray *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier:groupIdentifier];
        if (eventArray) {
            for (NSDictionary *dict in eventArray) {
                NSString *event = [dict[kSAEventName] copy];
                NSDictionary *properties = [dict[kSAEventProperties] copy];
                [[SensorsAnalyticsSDK sharedInstance] track:event withProperties:properties];
            }
            [[SAAppExtensionDataManager sharedInstance] deleteEventsWithGroupIdentifier:groupIdentifier];
            if (completion) {
                completion(groupIdentifier, eventArray);
            }
        }
    } @catch (NSException *exception) {
        SALogError(@"%@ error: %@", self, exception);
    }
}

@end
