//
// SAGeneralGestureViewProcessor.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
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
