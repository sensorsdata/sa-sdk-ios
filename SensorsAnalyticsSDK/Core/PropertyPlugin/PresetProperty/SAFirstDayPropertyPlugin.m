//
// SAFirstDayPropertyPlugin.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2022/5/5.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFirstDayPropertyPlugin.h"
#import "SAStoreManager.h"
#import "SADateFormatter.h"
#import "SAConstants+Private.h"


/// 是否首日
NSString * const kSAPresetPropertyIsFirstDay = @"$is_first_day";

@interface SAFirstDayPropertyPlugin()

@property (nonatomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SAFirstDayPropertyPlugin

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        dispatch_async(queue, ^{
            [self unarchiveFirstDay];
        });
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self unarchiveFirstDay];
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    // 是否首日访问，只有 track/bind/unbind 事件添加 $is_first_day 属性
    return filter.type & (SAEventTypeTrack | SAEventTypeBind | SAEventTypeUnbind);
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityHigh;
}

- (void)prepare {
    [self readyWithProperties:@{kSAPresetPropertyIsFirstDay: @([self isFirstDay])}];
}

#pragma mark – Public Methods
- (BOOL)isFirstDay {
    __block BOOL isFirstDay = NO;
    dispatch_block_t readFirstDayBlock = ^(){
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        NSString *current = [dateFormatter stringFromDate:[NSDate date]];
        isFirstDay = [self.firstDay isEqualToString:current];
    };

    if (self.queue) {
        sensorsdata_dispatch_safe_sync(self.queue, readFirstDayBlock);
    } else {
        readFirstDayBlock();
    }
    return isFirstDay;
}

#pragma mark – Private Methods
- (void)unarchiveFirstDay {
    self.firstDay = [[SAStoreManager sharedInstance] objectForKey:@"first_day"];
    if (!self.firstDay) {
        NSDateFormatter *dateFormatter = [SADateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
        [[SAStoreManager sharedInstance] setObject:self.firstDay forKey:@"first_day"];
    }
}

@end
