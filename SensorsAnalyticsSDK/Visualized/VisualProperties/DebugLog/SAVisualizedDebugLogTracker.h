//
//  SAVisualizedDebugLogTracker.h
//  Pods-SensorsData
//
//  Created by 储强盛 on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import "SAEventIdentifier.h"
NS_ASSUME_NONNULL_BEGIN

/// 诊断日志
@interface SAVisualizedDebugLogTracker : NSObject

/// 所有日志信息
@property (atomic, strong, readonly) NSMutableArray<NSMutableDictionary *> *debugLogInfos;

/// 元素点击事件信息
- (void)addTrackEventWithView:(UIView *)view withConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
