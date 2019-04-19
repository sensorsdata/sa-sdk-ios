//
//  SAAuxiliaryToolManager.h
//  SensorsAnalyticsSDK
//
//  Created by 向作为 on 2018/9/7.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAVisualizedAutoTrackConnection.h"
#import "SAHeatMapConnection.h"
NS_ASSUME_NONNULL_BEGIN

@interface SAAuxiliaryToolManager : NSObject
+ (instancetype)sharedInstance;

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url  isWifi:(BOOL)isWifi;


- (BOOL)isHeatMapURL:(NSURL *)url;
- (BOOL)isVisualizedAutoTrackURL:(NSURL *)url;
- (BOOL)isDebugModeURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
