//
// SASlinkCreator.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/7/7.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SASlinkCreator.h"
#import "SAReachability.h"
#import "SAJSONUtil.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK.h"
#import "SALog.h"
#import "SADeepLinkConstants.h"
#import "SAConstants+Private.h"


@implementation SATUTMProperties

@end

@interface SASlinkResponse ()

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy, nullable) NSString *slink;
@property (nonatomic, copy) NSString *commonRedirectURI;

- (instancetype)initWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode commonRedirectURI:(NSString *)commonRedirectURI;

@end

@implementation SASlinkResponse

- (instancetype)initWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode commonRedirectURI:(NSString *)commonRedirectURI {
    self = [super init];
    if (self) {
        _slink = slink;
        _slinkID = slinkID;
        _message = message.length > 200 ? [message substringToIndex:200] : message;
        _statusCode = statusCode;
        _commonRedirectURI = commonRedirectURI;
    }
    return self;
}

@end

@interface SASlinkCreator ()

//required params
@property (nonatomic, copy) NSString *templateID;
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSString *commonRedirectURI;
@property (nonatomic, copy) NSString *accessToken;

@property (nonatomic, copy) NSString *channelType;
@property (nonatomic, copy) NSString *projectName;


@end

@implementation SASlinkCreator

- (instancetype)initWithTemplateID:(NSString *)templateID channelName:(NSString *)channelName commonRedirectURI:(NSString *)commonRedirectURI accessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        _templateID = templateID;
        _channelName = channelName;
        _commonRedirectURI = commonRedirectURI;
        _accessToken = accessToken;
        _landingPageType = SATLandingPageTypeUndefined;
        _channelType = @"app_share";
    }
    return self;
}

- (void)createSlinkWithCompletion:(void (^)(SASlinkResponse * _Nonnull))completion {
    //check network reachable
    if (![SAReachability sharedInstance].reachable) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoNetwork") statusCode:kSADynamicSlinkStatusCodeNoNetwork];
        completion(response);
        return;
    }
    //check custom domain
    NSString *customADChannelURL = SensorsAnalyticsSDK.sdkInstance.configOptions.customADChannelURL;
    if (![customADChannelURL isKindOfClass:[NSString class]] || customADChannelURL.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoDomain") statusCode:kSADynamicSlinkStatusCodeoNoDomain];
        completion(response);
        return;
    }
    //check access token
    if (![self.accessToken isKindOfClass:[NSString class]] || self.accessToken.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoAccessToken") statusCode:kSADynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check project
    NSString *project = SensorsAnalyticsSDK.sdkInstance.network.project;
    if (![project isKindOfClass:[NSString class]] || project.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoProject") statusCode:kSADynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check templateID
    if (![self.templateID isKindOfClass:[NSString class]] || self.templateID.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoTemplateID") statusCode:kSADynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check channel name
    if (![self.channelName isKindOfClass:[NSString class]] || self.channelName.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoChannelName") statusCode:kSADynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check commonRedirectURI
    if (![self.commonRedirectURI isKindOfClass:[NSString class]] || self.commonRedirectURI.length < 1) {
        SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageNoRedirectURI") statusCode:kSADynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }

    //request dynamic slink
    NSDictionary *params = [self buildSlinkParams];
    NSURLRequest *request = [self buildSlinkRequestWithParams:params];
    NSURLSessionDataTask *task = [[SAHTTPSession sharedInstance] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable httpResponse, NSError * _Nullable error) {
        if (!httpResponse) {
            SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:error.localizedDescription statusCode:error.code];
            completion(response);
            return;
        }
        NSInteger statusCode = httpResponse.statusCode;
        NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
        NSDictionary *result = [SAJSONUtil JSONObjectWithData:data];
        if (![result isKindOfClass:[NSDictionary class]]) {
            SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:message statusCode:statusCode];
            completion(response);
            return;
        }
        message = result[@"msg"] ? : message;
        if (httpResponse.statusCode == 200) {
            if (!result[@"code"]) {
                SASlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:SALocalizedString(@"SADynamicSlinkMessageResponseError") statusCode:kSADynamicSlinkStatusCodeResponseError];
                completion(response);
                return;
            }
            statusCode = [result[@"code"] respondsToSelector:@selector(integerValue)] ? [result[@"code"] integerValue] : statusCode;
            NSDictionary *slinkData = result[@"data"];
            NSString *slink = nil;
            NSString *slinkID = nil;
            if ([slinkData isKindOfClass:[NSDictionary class]]) {
                slink = slinkData[@"short_url"];
                slinkID = slinkData[@"slink_id"];
            }
            SASlinkResponse *response = [self responseWithSlink:slink slinkID:slinkID message:message statusCode:statusCode];
            completion(response);
            return;
        }
        SASlinkResponse *slinkResponse = [self responseWithSlink:nil slinkID:nil message:message statusCode:statusCode];
        completion(slinkResponse);
    }];
    [task resume];
}

- (SASlinkResponse *)responseWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode {
    SASlinkResponse *response = [[SASlinkResponse alloc] initWithSlink:slink slinkID:slinkID message:message statusCode:statusCode commonRedirectURI:self.commonRedirectURI];
    [self trackEventWithSlinkResponse:response];
    return response;
}

- (void)trackEventWithSlinkResponse:(SASlinkResponse *)response {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[kSADynamicSlinkEventPropertyChannelType] = self.channelType;
    properties[kSADynamicSlinkEventPropertyChannelName] = self.channelName ? : @"";
    properties[kSADynamicSlinkEventPropertySource] = @"iOS";
    properties[kSADynamicSlinkEventPropertyData] = @"";
    properties[kSADynamicSlinkEventPropertyShortURL] = response.slink ? : @"";
    properties[kSADynamicSlinkEventPropertyStatus] = @(response.statusCode);
    properties[kSADynamicSlinkEventPropertyMessage] = response.message;
    properties[kSADynamicSlinkEventPropertyID] = response.slinkID ? : @"";
    properties[kSADynamicSlinkEventPropertyTemplateID] = self.templateID ? : @"";
    properties[kSADynamicSlinkEventPropertyType] = kSADynamicSlinkEventPropertyTypeDynamic;
    [[SensorsAnalyticsSDK sharedInstance] track:kSADynamicSlinkEventName withProperties:[properties copy]];
}

- (NSDictionary *)buildSlinkParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[kSADynamicSlinkParamProject] = SensorsAnalyticsSDK.sdkInstance.network.project;
    params[kSADynamicSlinkParamTemplateID] = self.templateID;
    params[kSADynamicSlinkParamChannelType] = self.channelType;
    params[kSADynamicSlinkParamChannelName] = self.channelName;
    if (self.name) {
        params[kSADynamicSlinkParamName] = self.name;
    }
    if (self.customParams) {
        params[kSADynamicSlinkParamCustom] = self.customParams;
    }
    if (self.routeParam) {
        params[kSADynamicSlinkParamRoute] = self.routeParam;
    }
    if (self.uriSchemeSuffix) {
        params[kSADynamicSlinkParamURIScheme] = self.uriSchemeSuffix;
    }
    if (self.landingPageType == SATLandingPageTypeIntelligence) {
        params[kSADynamicSlinkParamLandingPageType] = @"intelligence";
    } else if (self.landingPageType == SATLandingPageTypeOther) {
        params[kSADynamicSlinkParamLandingPageType] = @"other";
    } else {
        SALogInfo(@"Undefined Slink landing page type: %lu", self.landingPageType);
    }
    if (self.landingPage) {
        params[kSADynamicSlinkParamLandingPage] = self.landingPage;
    }
    if (self.redirectURLOnOtherDevice) {
        params[kSADynamicSlinkParamJumpAddress] = self.redirectURLOnOtherDevice;
    }
    if ([self.systemParams isKindOfClass:[NSDictionary class]]) {
        params[kSADynamicSlinkParamSystemParams] = [self.systemParams copy];
    }
    if (!self.utmProperties) {
        return [params copy];
    }
    NSMutableDictionary *utmProperties = [NSMutableDictionary dictionary];
    if (self.utmProperties.source) {
        utmProperties[kSADynamicSlinkParamUTMSource] = self.utmProperties.source;
    }
    if (self.utmProperties.campaign) {
        utmProperties[kSADynamicSlinkParamUTMCampaign] = self.utmProperties.campaign;
    }
    if (self.utmProperties.medium) {
        utmProperties[kSADynamicSlinkParamUTMMedium] = self.utmProperties.medium;
    }
    if (self.utmProperties.term) {
        utmProperties[kSADynamicSlinkParamUTMTerm] = self.utmProperties.term;
    }
    if (self.utmProperties.content) {
        utmProperties[kSADynamicSlinkParamUTMContent] = self.utmProperties.content;
    }
    params[kSADynamicSlinkParamFixedUTM] = [utmProperties copy];

    return [params copy];
}

- (NSURLRequest *)buildSlinkRequestWithParams:(NSDictionary *)params {
    NSString *customADChannelURL = SensorsAnalyticsSDK.sdkInstance.configOptions.customADChannelURL;
    if (![customADChannelURL isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSURL *slinkBaseURL = [NSURL URLWithString:customADChannelURL];
    if (!slinkBaseURL) {
        return nil;
    }
    NSURL *slinkURL = [slinkBaseURL URLByAppendingPathComponent:kSADynamicSlinkAPIPath];
    if (!slinkURL) {
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:slinkURL];
    request.timeoutInterval = 30;
    request.HTTPBody = [SAJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:self.accessToken forHTTPHeaderField:@"token"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end
