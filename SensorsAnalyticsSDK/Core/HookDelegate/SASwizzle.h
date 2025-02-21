// SASwizzler.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/20/16
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SASwizzle)

+ (BOOL)sa_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_;

+ (BOOL)sa_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError **)error_;

+ (BOOL)sa_swizzleMethod:(SEL)origSel_  withClass:(Class)altCla_ withMethod:(SEL)altSel_ error:(NSError **)error_;

@end

NS_ASSUME_NONNULL_END
