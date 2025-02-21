//
// SAFlowManager.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2022/2/17.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAFlowManager.h"
#import "SAInterceptor.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SACoreResources.h"

static NSString * const kSANodeFileName = @"sensors_analytics_node";
static NSString * const kSATaskFileName = @"sensors_analytics_task";
static NSString * const kSAFlowFileName = @"sensors_analytics_flow";
NSString * const kSATrackFlowId = @"sensorsdata_track_flow";
NSString * const kSAFlushFlowId = @"sensorsdata_flush_flow";
NSString * const kSATFlushFlowId = @"sensorsdata_ads_flush_flow";

@interface SAFlowManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, SANodeObject *> *nodes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SATaskObject *> *tasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SAFlowObject *> *flows;

@end

@implementation SAFlowManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAFlowManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAFlowManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _nodes = [NSMutableDictionary dictionary];
        _tasks = [NSMutableDictionary dictionary];
        _flows = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - load

- (void)loadFlows {
    [self.nodes addEntriesFromDictionary:[SANodeObject loadFromResources:[SACoreResources analyticsNodes]]];
    [self.tasks addEntriesFromDictionary:[SATaskObject loadFromResources:[SACoreResources analyticsTasks]]];
    [self.flows addEntriesFromDictionary:[SAFlowObject loadFromResources:[SACoreResources analyticsFlows]]];
}

#pragma mark - add

- (void)registerFlow:(SAFlowObject *)flow {
    NSParameterAssert(flow.flowID);
    if (!flow.flowID) {
        return;
    }
    self.flows[flow.flowID] = flow;
}

- (void)registerFlows:(NSArray<SAFlowObject *> *)flows {
    for (SAFlowObject *flow in flows) {
        [self registerFlow:flow];
    }
}

- (SAFlowObject *)flowForID:(NSString *)flowID {
    return self.flows[flowID];
}

#pragma mark - start

- (void)startWithFlowID:(NSString *)flowID input:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    NSParameterAssert(self.flows[flowID]);
    input.configOptions = self.configOptions;
    SAFlowObject *object = self.flows[flowID];
    if (!object) {
        return completion(input);
    }
    [self startWithFlow:object input:input completion:completion];
}

- (void)startWithFlow:(SAFlowObject *)flow input:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    input.configOptions = self.configOptions;
    [input.param addEntriesFromDictionary:flow.param];
    [self processWithFlow:flow taskIndex:0 input:input completion:^(SAFlowData * _Nonnull output) {
        if (completion) {
            completion(output);
        }
    }];
}

- (void)processWithFlow:(SAFlowObject *)flow taskIndex:(NSInteger)index input:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    SATaskObject *task = nil;
    if (index < flow.tasks.count) {
        task = flow.tasks[index];
    } else if (index < flow.taskIDs.count) {
        task = self.tasks[flow.taskIDs[index]];
    } else {
        return completion(input);
    }
    [input.param addEntriesFromDictionary:task.param];

    [self processWithTask:task nodeIndex:0 input:input completion:^(SAFlowData *output) {
        if (output.state == SAFlowStateStop) {
            return completion(output);
        }

        // 执行下一个 task
        [self processWithFlow:flow taskIndex:index + 1 input:output completion:completion];
    }];
}

- (void)processWithTask:(SATaskObject *)task nodeIndex:(NSInteger)index input:(SAFlowData *)input completion:(SAFlowDataCompletion)completion {
    SANodeObject *node = nil;
    if (index < task.nodes.count) {
        node = task.nodes[index];
    } else if (index < task.nodeIDs.count) {
        node = self.nodes[task.nodeIDs[index]];
    } else {
        return completion(input);
    }

    // 部分模块内的拦截器可能加载失败，此时节点不可用，则直接跳过
    if (!node.interceptor) {
        return [self processWithTask:task nodeIndex:index + 1 input:input completion:completion];
    }

    [node.interceptor processWithInput:input completion:^(SAFlowData *output) {
        if (output.message) {
            SALogError(@"The node(id: %@, name: %@, interceptor: %@) error: %@", node.nodeID, node.name, [node.interceptor class], output.message);
            output.message = nil;
        }
        if (output.state == SAFlowStateError) {
            SALogWarn(@"The node(id: %@, name: %@, interceptor: %@) stop the task(id: %@, name: %@).", node.nodeID, node.name, [node.interceptor class], task.taskID, task.name);
        }
        if (output.state == SAFlowStateStop || output.state == SAFlowStateError) {
            return completion(output);
        }

        // 执行下一个 node
        [self processWithTask:task nodeIndex:index + 1 input:output completion:completion];
    }];
}

@end
