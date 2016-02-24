//
//  SAUITableViewBinding.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//

#import "SAEventBinding.h"

@interface SAUITableViewBinding : SAEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventName:(NSString *)eventName
                     andTriggerId:(NSInteger)triggerId
                           onPath:(NSString *)path
                       isDeployed:(BOOL)deployed
                     withDelegate:(Class)delegateClass;

@end
