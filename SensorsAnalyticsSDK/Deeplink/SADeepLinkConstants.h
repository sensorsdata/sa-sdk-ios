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
extern NSString *const kSAResponsePropertyMessage;

// DeepLink
extern NSString *const kSAResponsePropertyParams;
extern NSString *const kSAResponsePropertyChannelParams;

// Deferred DeepLink
extern NSString *const kSAResponsePropertyParameter;
extern NSString *const kSAResponsePropertyADChannel;

NSSet* sensorsdata_preset_channel_keys(void);
