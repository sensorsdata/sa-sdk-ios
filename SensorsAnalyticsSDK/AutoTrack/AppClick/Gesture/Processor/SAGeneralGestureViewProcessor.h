//
// SAGeneralGestureViewProcessor.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAGeneralGestureViewProcessor : NSObject

/// 校验手势是否能够采集事件
@property (nonatomic, assign, readonly) BOOL isTrackable;

/// 手势事件采集时的控件元素
@property (nonatomic, strong, readonly) UIView *trackableView;

/// 初始化传入的手势
@property (nonatomic, strong, readonly) UIGestureRecognizer *gesture;

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture;

@end

@interface SALegacyAlertGestureViewProcessor : SAGeneralGestureViewProcessor
@end

@interface SANewAlertGestureViewProcessor : SAGeneralGestureViewProcessor
@end

@interface SALegacyMenuGestureViewProcessor : SAGeneralGestureViewProcessor
@end

@interface SAMenuGestureViewProcessor : SAGeneralGestureViewProcessor
@end

@interface SATableCellGestureViewProcessor : SAGeneralGestureViewProcessor
@end

@interface SACollectionCellGestureViewProcessor : SAGeneralGestureViewProcessor
@end

NS_ASSUME_NONNULL_END
