//
// SAPresetPropertyObject.h
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2022/1/7.
// Copyright © 2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SAPresetPropertyObject : NSObject

- (NSString *)manufacturer;
- (NSString *)os;
- (NSString *)osVersion;
- (NSString *)deviceModel;
- (NSString *)lib;
- (NSInteger)screenHeight;
- (NSInteger)screenWidth;
- (NSString *)appID;
- (NSString *)appName;
- (NSInteger)timezoneOffset;

- (NSMutableDictionary<NSString *, id> *)properties;

@end

#if TARGET_OS_IOS
@interface SAPhonePresetProperty : SAPresetPropertyObject

@end

@interface SACatalystPresetProperty : SAPresetPropertyObject

@end
#endif

#if TARGET_OS_OSX
@interface SAMacPresetProperty : SAPresetPropertyObject

@end
#endif

#if TARGET_OS_TV
@interface SATVPresetProperty : SAPresetPropertyObject

@end
#endif

#if TARGET_OS_WATCH
@interface SAWatchPresetProperty : SAPresetPropertyObject
@end
#endif

NS_ASSUME_NONNULL_END
