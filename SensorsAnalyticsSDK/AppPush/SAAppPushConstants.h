//
// SAAppPushConstants.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2021/1/18.
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
