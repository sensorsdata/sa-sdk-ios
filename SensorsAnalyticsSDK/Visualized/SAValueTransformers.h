//
// SAValueTransformers.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/20/16
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SAPassThroughValueTransformer : NSValueTransformer

@end

@interface SABOOLToNSNumberValueTransformer : NSValueTransformer

@end

@interface SACGPointToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGRectToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGSizeToNSDictionaryValueTransformer : NSValueTransformer

@end
