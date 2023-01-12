//
// SADeepLinkConstants.h
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2021/12/10.
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

#pragma mark - Event Name
extern NSString *const kSAAppDeepLinkLaunchEvent;
extern NSString *const kSADeepLinkMatchedResultEvent;
extern NSString *const kSADeferredDeepLinkJumpEvent;

#pragma mark - Other
extern NSString *const kSADeepLinkLatestChannelsFileName;
extern NSString *const kSADeferredDeepLinkStatus;

#pragma mark - Event Property
extern NSString *const kSAEventPropertyDeepLinkURL;
extern NSString *const kSAEventPropertyDeepLinkOptions;
extern NSString *const kSAEventPropertyDeepLinkFailReason;
extern NSString *const kSAEventPropertyDuration;
extern NSString *const kSAEventPropertyADMatchType;
extern NSString *const kSAEventPropertyADDeviceInfo;
extern NSString *const kSAEventPropertyADChannel;
extern NSString *const kSAEventPropertyADSLinkID;

#pragma mark - Request Property
extern NSString *const kSARequestPropertyUserAgent;

extern NSString *const kSARequestPropertyIDs;
extern NSString *const kSARequestPropertyUA;
extern NSString *const kSARequestPropertyOS;
extern NSString *const kSARequestPropertyOSVersion;
extern NSString *const kSARequestPropertyModel;
extern NSString *const kSARequestPropertyNetwork;
extern NSString *const kSARequestPropertyTimestamp;
extern NSString *const kSARequestPropertyAppID;
extern NSString *const kSARequestPropertyAppVersion;
extern NSString *const kSARequestPropertyAppParameter;
extern NSString *const kSARequestPropertyProject;

#pragma mark - Response Property

extern NSString *const kSAResponsePropertySLinkID;

extern NSString *const kSAResponsePropertyCode;
extern NSString *const kSAResponsePropertyErrorMessage;
extern NSString *const kSAResponsePropertyErrorMsg;
extern NSString *const kSAResponsePropertyMessage;

// DeepLink
extern NSString *const kSAResponsePropertyParams;
extern NSString *const kSAResponsePropertyChannelParams;

// Deferred DeepLink
extern NSString *const kSAResponsePropertyParameter;
extern NSString *const kSAResponsePropertyADChannel;

NSSet* sensorsdata_preset_channel_keys(void);

//dynamic slink related message

//dynamic slink related code
extern NSInteger kSADynamicSlinkStatusCodeSuccess;
extern NSInteger kSADynamicSlinkStatusCodeLessParams;
extern NSInteger kSADynamicSlinkStatusCodeNoNetwork;
extern NSInteger kSADynamicSlinkStatusCodeoNoDomain;
extern NSInteger kSADynamicSlinkStatusCodeResponseError;

//dynamic slink event name and properties
extern NSString *const kSADynamicSlinkEventName;
extern NSString *const kSADynamicSlinkEventPropertyChannelType;
extern NSString *const kSADynamicSlinkEventPropertyChannelName;
extern NSString *const kSADynamicSlinkEventPropertySource;
extern NSString *const kSADynamicSlinkEventPropertyData;
extern NSString *const kSADynamicSlinkEventPropertyShortURL;
extern NSString *const kSADynamicSlinkEventPropertyStatus;
extern NSString *const kSADynamicSlinkEventPropertyMessage;
extern NSString *const kSADynamicSlinkEventPropertyID;
extern NSString *const kSADynamicSlinkEventPropertyTemplateID;
extern NSString *const kSADynamicSlinkEventPropertyType;
extern NSString *const kSADynamicSlinkEventPropertyTypeDynamic;
extern NSString *const kSADynamicSlinkEventPropertyCustomParams;

//dynamic slink API path
extern NSString *const kSADynamicSlinkAPIPath;

//dynamic slink API params
extern NSString *const kSADynamicSlinkParamProject;
extern NSString *const kSADynamicSlinkParamTemplateID;
extern NSString *const kSADynamicSlinkParamType;
extern NSString *const kSADynamicSlinkParamName;
extern NSString *const kSADynamicSlinkParamChannelType;
extern NSString *const kSADynamicSlinkParamChannelName;
extern NSString *const kSADynamicSlinkParamFixedUTM;
extern NSString *const kSADynamicSlinkParamUTMSource;
extern NSString *const kSADynamicSlinkParamUTMCampaign;
extern NSString *const kSADynamicSlinkParamUTMMedium;
extern NSString *const kSADynamicSlinkParamUTMTerm;
extern NSString *const kSADynamicSlinkParamUTMContent;
extern NSString *const kSADynamicSlinkParamCustom;
extern NSString *const kSADynamicSlinkParamRoute;
extern NSString *const kSADynamicSlinkParamURIScheme;
extern NSString *const kSADynamicSlinkParamLandingPageType;
extern NSString *const kSADynamicSlinkParamLandingPage;
extern NSString *const kSADynamicSlinkParamJumpAddress;
extern NSString *const kSADynamicSlinkParamSystemParams;

//slink response key
extern NSString *const kSADynamicSlinkResponseKeyCustomParams;
