//
// SAPropertyValidator.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/4/12.
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

#import <Foundation/Foundation.h>
#import "SAValidator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SAPropertyKeyProtocol <NSObject>

- (void)sensorsdata_isValidPropertyKeyWithError:(NSError **)error;

@end

@protocol SAPropertyValueProtocol <NSObject>

- (id _Nullable)sensorsdata_propertyValueWithKey:(NSString *)key error:(NSError **)error;

@end

@protocol SAEventPropertyValidatorProtocol <NSObject>

- (id _Nullable)sensorsdata_validKey:(NSString *)key value:(id)value error:(NSError **)error;

@end

@interface NSString (SAProperty)<SAPropertyKeyProtocol, SAPropertyValueProtocol>
@end

@interface NSNumber (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSDate (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSSet (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSArray (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSNull (SAProperty)<SAPropertyValueProtocol>
@end

@interface NSDictionary (SAProperty) <SAEventPropertyValidatorProtocol>
@end

@interface SAPropertyValidator : NSObject

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties;
+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties validator:(id<SAEventPropertyValidatorProtocol>)validator;

@end

NS_ASSUME_NONNULL_END
