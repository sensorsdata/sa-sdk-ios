//
//  SAEventBinding.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SAObjectSelector.h"

@interface SAEventBinding : NSObject <NSCoding>

// Trigger的ID
@property (nonatomic) NSInteger triggerId;
// Trigger是否已正式部署
@property (nonatomic) BOOL deployed;
// UUID
@property (nonatomic) NSString *name;
// Trigger路径
@property (nonatomic) SAObjectSelector *path;
// 事件名称
@property (nonatomic) NSString *eventName;

// 绑定的Class
@property (nonatomic, assign) Class swizzleClass;

/**
 @property
 
 @abstract
 Whether this specific binding is currently running on the device.

 @discussion
 This property will not be restored on unarchive, as the binding will need
 to be run again once the app is restarted.
 */
@property (nonatomic) BOOL running;

+ (id)bindingWithJSONObject:(id)object;

- (instancetype)init __unavailable;
- (instancetype)initWithEventName:(NSString *)eventName
                     andTriggerId:(NSInteger)triggerId
                           onPath:(NSString *)path
                       isDeployed:(BOOL)deployed;
/**
 Intercepts track calls and adds a property indicating the track event
 was from a binding
 */
- (void)track:(NSString *)event withProperties:(NSDictionary *)properties;

/**
 Method stubs. Implement them in subclasses
 */
+ (NSString *)typeName;
- (void)execute;
- (void)stop;

@end
