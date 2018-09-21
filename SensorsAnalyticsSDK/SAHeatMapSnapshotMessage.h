//
//  SADesignerSnapshotMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SAAbstractHeatMapMessage.h"

@class SAObjectSerializerConfig;

extern NSString *const SAHeatMapSnapshotRequestMessageType;

#pragma mark -- Snapshot Request

@interface SAHeatMapSnapshotRequestMessage : SAAbstractHeatMapMessage

+ (instancetype)message;

@property (nonatomic, readonly) SAObjectSerializerConfig *configuration;

@end

#pragma mark -- Snapshot Response

@interface SAHeatMapSnapshotResponseMessage : SAAbstractHeatMapMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, strong) NSString *imageHash;

@end
