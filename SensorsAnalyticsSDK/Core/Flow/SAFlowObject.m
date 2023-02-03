//
// SAFlowObject.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
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

#import "SAFlowObject.h"
#import "SAJSONUtil.h"

static NSString * const kSAFlowObjectId = @"id";
static NSString * const kSAFlowObjectName = @"name";
static NSString * const kSAFlowObjectTasks = @"tasks";
static NSString * const kSAFlowObjectParam = @"param";

static NSString * const kSAFlowFileName = @"sensors_analytics_flow.json";

@implementation SAFlowObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kSAFlowObjectId]);
    NSParameterAssert(dictionary[kSAFlowObjectName]);
    self = [super init];
    if (self) {
        _flowID = dictionary[kSAFlowObjectId];
        _name = dictionary[kSAFlowObjectName];
        _param = dictionary[kSAFlowObjectParam];

        NSArray *array = dictionary[kSAFlowObjectTasks];
        if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *tasks = [NSMutableArray array];
            for (NSDictionary *dic in array) {
                [tasks addObject:[[SATaskObject alloc] initWithDictionary:dic]];
            }
            _tasks = tasks;
        } else {
            _taskIDs = array;
        }
    }
    return self;
}

- (instancetype)initWithFlowID:(NSString *)flowID name:(NSString *)name tasks:(NSArray<SATaskObject *> *)tasks {
    self = [super init];
    if (self) {
        _flowID = flowID;
        _name = name;
        _tasks = tasks;
    }
    return self;
}

- (SATaskObject *)taskForID:(NSString *)taskID {
    if (![taskID isKindOfClass:NSString.class]) {
        return nil;
    }
    for (SATaskObject *task in self.tasks) {
        if ([task.taskID isEqualToString:taskID]) {
            return task;
        }
    }
    return nil;
}

+ (NSDictionary<NSString *, SAFlowObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSString *jsonPath = [bundle pathForResource:kSAFlowFileName ofType:nil];
    if (!jsonPath) {
        return nil;
    }
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    return [self loadFromResources:array];
}

+ (NSDictionary<NSString *, SATaskObject *> *)loadFromResources:(NSArray *)array {
    NSMutableDictionary *flows = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        SAFlowObject *object = [[SAFlowObject alloc] initWithDictionary:dic];
        flows[object.flowID] = object;
    }
    return flows;
}

@end
