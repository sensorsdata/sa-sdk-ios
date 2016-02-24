//
//  SADesignerDeviceInfoMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAbstractDesignerMessage.h"

#pragma mark -- DeviceInfo Request

extern NSString *const SADesignerDeviceInfoRequestMessageType;

@interface SADesignerDeviceInfoRequestMessage : SAAbstractDesignerMessage

@end

#pragma mark -- DeviceInfo Response

@interface SADesignerDeviceInfoResponseMessage : SAAbstractDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *libName;
@property (nonatomic, copy) NSString *systemName;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSString *libVersion;
@property (nonatomic, copy) NSString *mainBundleIdentifier;
@property (nonatomic, copy) NSString *screenHeight;
@property (nonatomic, copy) NSString *screenWidth;

@end
