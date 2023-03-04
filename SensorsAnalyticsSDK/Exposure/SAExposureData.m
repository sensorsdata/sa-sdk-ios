//
// SAExposureData.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/8/9.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAExposureData.h"

@interface SAExposureData ()

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSDictionary *properties;
@property (nonatomic, copy) NSString *exposureIdentifier;
@property (nonatomic, copy) SAExposureConfig *config;

@end

@implementation SAExposureData

- (instancetype)initWithEvent:(NSString *)event {
    return [self initWithEvent:event properties:nil exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier {
    return [self initWithEvent:event properties:properties exposureIdentifier:exposureIdentifier config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties config:(SAExposureConfig *)config {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:config];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier config:(SAExposureConfig *)config {
    self = [super init];
    if (self) {
        _event = event;
        _properties = properties;
        _exposureIdentifier = exposureIdentifier;
        _config = config;
    }
    return self;
}
@end
