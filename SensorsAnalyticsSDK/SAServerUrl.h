//
//  SAServerUrl.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2018/1/2.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SAServerUrl : NSObject
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *host;
@property (nonatomic, copy, readonly) NSString *project;
@property (nonatomic, copy, readonly) NSString *token;

- (instancetype)initWithUrl:(NSString *)url;
- (BOOL)check:(SAServerUrl *)serverUrl;
@end
