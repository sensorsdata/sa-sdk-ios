//
// SAGestureViewProcessorFactory.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/19.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import "SAGeneralGestureViewProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAGestureViewProcessorFactory : NSObject

+ (SAGeneralGestureViewProcessor *)processorWithGesture:(UIGestureRecognizer *)gesture;

@end


NS_ASSUME_NONNULL_END
