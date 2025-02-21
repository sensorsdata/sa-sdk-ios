//
// SADeviceIDPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/10/25.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SADeviceIDPropertyPlugin.h"
#import "SAPropertyPluginManager.h"
#import "SAIdentifier.h"

NSString * const kSADeviceIDPropertyPluginAnonymizationID = @"$anonymization_id";
NSString *const kSADeviceIDPropertyPluginDeviceID = @"$device_id";

@implementation SADeviceIDPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return kSAPropertyPluginPrioritySuper;
}

- (void)prepare {
    NSString *hardwareID = [SAIdentifier hardwareID];
    NSData *data = [hardwareID dataUsingEncoding:NSUTF8StringEncoding];
    NSString *anonymizationID = [data base64EncodedStringWithOptions:0];

    [self readyWithProperties:self.disableDeviceId ? @{kSADeviceIDPropertyPluginAnonymizationID: anonymizationID} : @{kSADeviceIDPropertyPluginDeviceID: hardwareID}];
}

@end
