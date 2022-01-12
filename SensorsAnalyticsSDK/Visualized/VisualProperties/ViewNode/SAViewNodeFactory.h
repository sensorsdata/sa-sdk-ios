//
// SAViewNodeFactory.h
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/29.
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
#import <UIKit/UIKit.h>
#import "SAViewNode.h"

NS_ASSUME_NONNULL_BEGIN

/// 构造工厂
@interface SAViewNodeFactory : NSObject

+ (nullable SAViewNode *)viewNodeWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
