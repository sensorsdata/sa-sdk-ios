//
//  UIGestureRecognizer+SAAutoTrack.h
//  SensorsAnalyticsSDK
//
//  Created by 储强盛 on 2018/10/25.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import "SAAutoTrackProperty.h"
#import "SAGestureTarget.h"
#import "SAGestureTargetActionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (SAAutoTrack)

@property (nonatomic, strong, readonly) NSMutableArray <SAGestureTargetActionModel *>*sensorsdata_targetActionModels;
@property (nonatomic, strong, readonly) SAGestureTarget *sensorsdata_gestureTarget;

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action;
- (void)sensorsdata_addTarget:(id)target action:(SEL)action;
- (void)sensorsdata_removeTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
