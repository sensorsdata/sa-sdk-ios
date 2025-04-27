//
//  SAModuleProtocol.h
//  SensorsAnalyticsSDK
//
//  Created by 陈玉国 on 2024/10/30.
//

#import <Foundation/Foundation.h>

@class SAConfigOptions;

NS_ASSUME_NONNULL_BEGIN

@protocol SAModuleProtocol <NSObject>

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) SAConfigOptions *configOptions;
+ (instancetype)defaultManager;

@optional
- (void)updateServerURL:(NSString *)serverURL;

@end

NS_ASSUME_NONNULL_END

#pragma mark -

@protocol SAPropertyModuleProtocol <SAModuleProtocol>

@optional
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end
