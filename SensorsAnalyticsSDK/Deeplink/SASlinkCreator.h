//
// SASlinkCreator.h
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/7/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SATLandingPageType) {
    SATLandingPageTypeIntelligence = 0,
    SATLandingPageTypeOther,
    SATLandingPageTypeUndefined,
};

@interface SATUTMProperties : NSObject

/// channel_utm_campaign
@property (nonatomic, copy, nullable) NSString *campaign;

/// channel_utm_source
@property (nonatomic, copy, nullable) NSString *source;

/// channel_utm_medium
@property (nonatomic, copy, nullable) NSString *medium;

/// channel_utm_term
@property (nonatomic, copy, nullable) NSString *term;

/// channel_utm_content
@property (nonatomic, copy, nullable) NSString *content;

@end

@interface SASlinkResponse : NSObject

/// status code when creating slink, such as 0 indicate that slink was created successfully
@property (nonatomic, assign, readonly) NSInteger statusCode;

/// message when creaing slink, each status code matched a message
@property (nonatomic, copy, readonly) NSString *message;

/// created slink, maybe nil
@property (nonatomic, copy, nullable, readonly) NSString *slink;

/// slink ID, maybe nil
@property (nonatomic, copy, nullable, readonly) NSString *slinkID;

/// common redirect uri, once slink created failed, use this instead
@property (nonatomic, copy, readonly) NSString *commonRedirectURI;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@interface SASlinkCreator : NSObject

/// name for slink
@property (nonatomic, copy, nullable) NSString *name;

/// url scheme suffix, such as "11/8A/X"
@property (nonatomic, copy, nullable) NSString *uriSchemeSuffix;

/// landing page type, such as intelligence or other
@property (nonatomic, assign) SATLandingPageType landingPageType;

/// redirect url once slink opened on other devices, such as PC, not mobile devices
@property (nonatomic, copy, nullable) NSString *redirectURLOnOtherDevice;

/// route param for slink, such as "a=123&b=test"
@property (nonatomic, copy, nullable) NSString *routeParam;

/// landing page settings
@property (nonatomic, copy, nullable) NSDictionary *landingPage;

/// custom params for slink
@property (nonatomic, copy, nullable) NSDictionary *customParams;

/// utm properties
@property (nonatomic, strong, nullable) SATUTMProperties *utmProperties;

/// system params
@property (nonatomic, copy, nullable) NSDictionary *systemParams;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// init method for slink creator
/// @param templateID slink template ID
/// @param channelName channel name
/// @param commonRedirectURI common redirect url
/// @param accessToken access token
- (instancetype)initWithTemplateID:(NSString *)templateID channelName:(NSString *)channelName commonRedirectURI:(NSString *)commonRedirectURI accessToken:(NSString *)accessToken;


/// create slink
/// @param completion completion when creating slink
- (void)createSlinkWithCompletion:(nullable void (^)(SASlinkResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
