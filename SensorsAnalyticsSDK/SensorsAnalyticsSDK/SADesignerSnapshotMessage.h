//
//  SADesignerSnapshotMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SAAbstractDesignerMessage.h"

@class SAObjectSerializerConfig;

extern NSString *const SADesignerSnapshotRequestMessageType;

#pragma mark -- Snapshot Request

@interface SADesignerSnapshotRequestMessage : SAAbstractDesignerMessage

+ (instancetype)message;

@property (nonatomic, readonly) SAObjectSerializerConfig *configuration;

@end

#pragma mark -- Snapshot Response

@interface SADesignerSnapshotResponseMessage : SAAbstractDesignerMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, strong) NSString *imageHash;

@end
