//
// SAGestureTargetActionModel.m
// SensorsAnalyticsSDK
//
// Created by yuqiang on 2021/2/8.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAGestureTargetActionModel.h"

@implementation SAGestureTargetActionModel

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super init]) {
        self.target = target;
        self.action = action;
    }
    return self;
}

- (BOOL)isEqualToTarget:(id)target andAction:(SEL)action {
    return (self.target == target) && [NSStringFromSelector(self.action) isEqualToString:NSStringFromSelector(action)];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"target = %@; action = %@; description = %@", self.target, NSStringFromSelector(self.action), [super description]];
}

- (BOOL)isValid {
    return [self.target respondsToSelector:self.action];
}

+ (SAGestureTargetActionModel * _Nullable)containsObjectWithTarget:(id)target andAction:(SEL)action fromModels:(NSArray <SAGestureTargetActionModel *>*)models {
    for (SAGestureTargetActionModel *model in models) {
        if ([model isEqualToTarget:target andAction:action]) {
            return model;
        }
    }
    return nil;
}

+ (NSArray <SAGestureTargetActionModel *>*)filterValidModelsFrom:(NSArray <SAGestureTargetActionModel *>*)models {
    NSMutableArray *result = [NSMutableArray array];
    for (SAGestureTargetActionModel *model in models) {
        if (model.isValid) {
            [result addObject:model];
        }
    }
    return [result copy];
}

@end
