//
// SAVisualizedDebugLogTracker.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/3/3.
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

#import "SAVisualizedDebugLogTracker.h"
#import "SAVisualizedLogger.h"
#import "SAVisualizedUtils.h"
#import "SAAutoTrackUtils.h"
#import "SAViewNode.h"
#import "SALog+Private.h"
#import "UIView+SAVisualProperties.h"
#import "SAConstants+Private.h"

@interface SAVisualizedDebugLogTracker()<SAVisualizedLoggerDelegate>
@property (atomic, strong, readwrite) NSMutableArray<NSMutableDictionary *> *debugLogInfos;
@property (nonatomic, strong) SAVisualizedLogger *logger;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
/// node 节点的行号
@property (nonatomic, assign) NSInteger nodeRowIndex;

@end

@implementation SAVisualizedDebugLogTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *serialQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.SAVisualizedDebugLogTracker.%p", self];
        _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        [self addDebugLogger];
        _debugLogInfos = [NSMutableArray array];

    }
    return self;
}

- (void)addDebugLogger {
    // 添加 log 实现
    SAVisualizedLogger *visualizedLogger = [[SAVisualizedLogger alloc] init];
    [SALog addLogger:visualizedLogger];

    visualizedLogger.delegate = self;
    self.logger = visualizedLogger;
}

#pragma mark SAVisualizedLoggerDelegate
- (void)loggerMessage:(NSDictionary *)messageDic {
    if (!messageDic) {
        return;
    }
    NSMutableDictionary *eventLogInfo = [self.debugLogInfos lastObject];
    NSMutableArray *messages = eventLogInfo[@"messages"];
    [messages addObject:messageDic];
}

#pragma mark - addDebugLog
- (void)addTrackEventWithView:(UIView *)view withConfig:(NSDictionary *)config {
    SAViewNode *viewNode = view.sensorsdata_viewNode;
    if (!viewNode) {
        return;
    }
    NSMutableDictionary *appClickEventInfo = [NSMutableDictionary dictionary];
    appClickEventInfo[@"event_type"] = @"appclick";
    appClickEventInfo[@"element_path"] = viewNode.elementPath;
    appClickEventInfo[@"element_position"] = viewNode.elementPosition;
    appClickEventInfo[@"element_content"] = viewNode.elementContent;
    appClickEventInfo[@"screen_name"] = viewNode.screenName;

    [self addTrackEventInfo:appClickEventInfo withConfig:config];
}

- (void)addTrackEventInfo:(NSDictionary *)eventInfo withConfig:(NSDictionary *)config {
    NSMutableDictionary *eventLogInfo = [NSMutableDictionary dictionary];
    [self.debugLogInfos addObject:eventLogInfo];

    // 1. 添加事件信息
    [eventLogInfo addEntriesFromDictionary:eventInfo];

    // 2. 解析配置信息
    eventLogInfo[@"config"] = config;

    // 3. 构建日志信息
    NSMutableArray *messages = [NSMutableArray array];
    eventLogInfo[@"messages"] = messages;

    // 4. 添加 node 信息
    [self addAllNodeInfo];
}

#pragma mark addNodeInfo
// 实现 node 递归遍历，打印节点树
- (void)addAllNodeInfo {
    // 主线程获取 keyWindow
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [SAVisualizedUtils currentValidKeyWindow];
        SAViewNode *rootNode = keyWindow.sensorsdata_viewNode.nextNode;

        // 异步递归遍历
        dispatch_async(self.serialQueue, ^{
            self.nodeRowIndex = 0;
            @try {
                NSString *nodeMessage = [self showViewHierarchy:rootNode level:0];
                NSMutableDictionary *eventLogInfo = [self.debugLogInfos lastObject];
                eventLogInfo[@"objects"] = nodeMessage;
            } @catch (NSException *exception) {
                NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"诊断信息" message:@"log node tree error: %@", exception];
                SALogWarn(@"%@", logMessage);
            }
        });
    });
}

// 显示每层 node 的信息
- (NSString *)showViewHierarchy:(SAViewNode *)node level:(NSInteger)level {
    NSMutableString *description = [NSMutableString string];

    NSMutableString *indent = [NSMutableString stringWithFormat:@"%ld",(long)self.nodeRowIndex];
    // 不同位数字后空格数不同，保证对齐
    NSInteger log =  self.nodeRowIndex > 0 ? log10(self.nodeRowIndex) : 0;
    NSInteger spaceCount = log > 3 ? 0 : 3 - log;
    for (NSInteger index = 0 ; index < spaceCount; index ++) {
        [indent appendString:@" "];
    }
    for (NSInteger i = 0; i < level; i++) {
        [indent appendString:@" |"];
    }

    self.nodeRowIndex ++;
    [description appendFormat:@"\n%@%@", indent, node];

    /* 此处执行 copy
     1. 遍历同时，可能存在主线程异步的 node 构建，从而修改 subNodes，防止遍历同时修改的崩溃
     2. 尽可能获取事件发生时刻的 node，而不是最新的
     */
    for (SAViewNode *node1 in [node.subNodes copy]) {
        [description appendFormat:@"%@", [self showViewHierarchy:node1 level:level + 1]];
    }
    return [description copy];
}

- (void)dealloc {
    // 移除注入的 logger
    [SALog removeLogger:self.logger];
}

@end
