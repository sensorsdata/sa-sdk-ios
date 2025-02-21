//
// SANotificationUtil.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SANotificationUtil.h"
#import "SAAppPushConstants.h"
#import "SAJSONUtil.h"
#import "SALog.h"

@implementation SANotificationUtil

+ (NSDictionary *)propertiesFromUserInfo:(NSDictionary *)userInfo {
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    if (userInfo[kSAPushServiceKeyJPUSH]) {
        properties[kSAEventPropertyNotificationServiceName] = kSAEventPropertyNotificationServiceNameJPUSH;
    }
    
    if (userInfo[kSAPushServiceKeyGeTui]) {
        properties[kSAEventPropertyNotificationServiceName] = kSAEventPropertyNotificationServiceNameGeTui;
    }
    
    //SF related properties
    NSString *sfDataString = userInfo[kSAPushServiceKeySF];
    
    if ([sfDataString isKindOfClass:[NSString class]]) {

        NSDictionary *sfProperties = [SAJSONUtil JSONObjectWithString:sfDataString];
        if ([sfProperties isKindOfClass:[NSDictionary class]]) {
            [properties addEntriesFromDictionary:[self propertiesFromSFData:sfProperties]];
        }
    }
    
    return [properties copy];
}

+ (NSDictionary *)propertiesFromSFData:(NSDictionary *)sfData {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSFPlanStrategyID] = sfData[kSFPlanStrategyID.sensorsdata_sfPushKey];
    properties[kSFChannelCategory] = sfData[kSFChannelCategory.sensorsdata_sfPushKey];
    properties[kSFAudienceID] = sfData[kSFAudienceID.sensorsdata_sfPushKey];
    properties[kSFChannelID] = sfData[kSFChannelID.sensorsdata_sfPushKey];
    properties[kSFLinkUrl] = sfData[kSFLinkUrl.sensorsdata_sfPushKey];
    properties[kSFPlanType] = sfData[kSFPlanType.sensorsdata_sfPushKey];
    properties[kSFChannelServiceName] = sfData[kSFChannelServiceName.sensorsdata_sfPushKey];
    properties[kSFMessageID] = sfData[kSFMessageID.sensorsdata_sfPushKey];
    properties[kSFPlanID] = sfData[kSFPlanID.sensorsdata_sfPushKey];
    properties[kSFStrategyUnitID] = sfData[kSFStrategyUnitID.sensorsdata_sfPushKey];
    properties[kSFEnterPlanTime] = sfData[kSFEnterPlanTime.sensorsdata_sfPushKey];
    return [properties copy];
}

@end

@implementation NSString (SFPushKey)

- (NSString *)sensorsdata_sfPushKey {
    NSString *prefix = @"$";
    if ([self hasPrefix:prefix]) {
        return [self substringFromIndex:[prefix length]];
    }
    return self;
}

@end
