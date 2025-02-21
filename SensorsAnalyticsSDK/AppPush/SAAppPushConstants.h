//
// SAAppPushConstants.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

//AppPush Notification related
extern NSString * const kSAEventNameNotificationClick;
extern NSString * const kSAEventPropertyNotificationTitle;
extern NSString * const kSAEventPropertyNotificationContent;
extern NSString * const kSAEventPropertyNotificationServiceName;
extern NSString * const kSAEventPropertyNotificationChannel;
extern NSString * const kSAEventPropertyNotificationServiceNameLocal;
extern NSString * const kSAEventPropertyNotificationServiceNameJPUSH;
extern NSString * const kSAEventPropertyNotificationServiceNameGeTui;
extern NSString * const kSAEventPropertyNotificationChannelApple;

//identifier for third part push service
extern NSString * const kSAPushServiceKeyJPUSH;
extern NSString * const kSAPushServiceKeyGeTui;
extern NSString * const kSAPushServiceKeySF;

//APNS related key
extern NSString * const kSAPushAppleUserInfoKeyAps;
extern NSString * const kSAPushAppleUserInfoKeyAlert;
extern NSString * const kSAPushAppleUserInfoKeyTitle;
extern NSString * const kSAPushAppleUserInfoKeyBody;

//sf_data related properties
extern NSString * const kSFMessageTitle;
extern NSString * const kSFPlanStrategyID;
extern NSString * const kSFChannelCategory;
extern NSString * const kSFAudienceID;
extern NSString * const kSFChannelID;
extern NSString * const kSFLinkUrl;
extern NSString * const kSFPlanType;
extern NSString * const kSFChannelServiceName;
extern NSString * const kSFMessageID;
extern NSString * const kSFPlanID;
extern NSString * const kSFStrategyUnitID;
extern NSString * const kSFEnterPlanTime;
extern NSString * const kSFMessageContent;
