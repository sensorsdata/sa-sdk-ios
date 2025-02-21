//
// SATaskObject.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/4/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SATaskObject.h"
#import "SAJSONUtil.h"
#import "SAValidator.h"

static NSString * const kSATaskObjectId = @"id";
static NSString * const kSATaskObjectName = @"name";
static NSString * const kSATaskObjectParam = @"param";
static NSString * const kSATaskObjectNodes = @"nodes";

static NSString * const kSATaskFileName = @"sensors_analytics_task";

@implementation SATaskObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kSATaskObjectId]);
    NSParameterAssert(dictionary[kSATaskObjectName]);
    self = [super init];
    if (self) {
        _taskID = dictionary[kSATaskObjectId];
        _name = dictionary[kSATaskObjectName];
        _param = dictionary[kSATaskObjectParam];

        NSArray *array = dictionary[kSATaskObjectNodes];
        if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *nodes = [NSMutableArray array];
            for (NSDictionary *dic in array) {
                [nodes addObject:[[SANodeObject alloc] initWithDictionary:dic]];
            }
            _nodes = nodes;
        } else {
            _nodeIDs = array;
        }
    }
    return self;
}

- (instancetype)initWithTaskID:(NSString *)taskID name:(NSString *)name nodes:(NSArray<SANodeObject *> *)nodes {
    self = [super init];
    if (self) {
        _taskID = taskID;
        _name = name;
        _nodes = [nodes mutableCopy];
    }
    return self;
}

- (void)insertNode:(SANodeObject *)node atIndex:(NSUInteger)index {
    if (index > self.nodes.count) {
        return;
    }
    [self.nodes insertObject:node atIndex:index];
}

- (NSInteger)indexOfNodeWithID:(NSString *)nodeID {
    __block NSInteger index = -1;
    if (![SAValidator isValidString:nodeID]) {
        return index;
    }
    [self.nodes enumerateObjectsUsingBlock:^(SANodeObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.nodeID isEqualToString:nodeID]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

+ (NSDictionary<NSString *, SATaskObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSURL *url = [bundle URLForResource:kSATaskFileName withExtension:@"json"];
    if (!url) {
        return nil;
    }
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfURL:url]];
    return [self loadFromResources:array];
}

+ (NSDictionary<NSString *, SATaskObject *> *)loadFromResources:(NSArray *)array {
    NSMutableDictionary *tasks = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        SATaskObject *object = [[SATaskObject alloc] initWithDictionary:dic];
        tasks[object.taskID] = object;
    }
    return tasks;
}

@end
