//
// SANodeObject.m
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

#import "SANodeObject.h"
#import "SAJSONUtil.h"

static NSString * const kSANodeObjectId = @"id";
static NSString * const kSANodeObjectName = @"name";
static NSString * const kSANodeObjectInterceptor = @"interceptor";
static NSString * const kSANodeObjectParam = @"param";

static NSString * const kSANodeFileName = @"sensors_analytics_node";

@interface SANodeObject ()

@property (nonatomic, strong) SAInterceptor *interceptor;

@end

@implementation SANodeObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kSANodeObjectId]);
    NSParameterAssert(dictionary[kSANodeObjectName]);
    NSParameterAssert(dictionary[kSANodeObjectInterceptor]);
    self = [super init];
    if (self) {
        _nodeID = dictionary[kSANodeObjectId];
        _name = dictionary[kSANodeObjectName];
        _interceptorClassName = dictionary[kSANodeObjectInterceptor];
        _param = dictionary[kSANodeObjectParam];
        
        Class cla = NSClassFromString(self.interceptorClassName);
        if (cla && [cla respondsToSelector:@selector(interceptorWithParam:)]) {
            _interceptor = [cla interceptorWithParam:self.param];
        }
    }
    return self;
}

- (instancetype)initWithNodeID:(NSString *)nodeID name:(NSString *)name interceptor:(SAInterceptor *)interceptor {
    NSParameterAssert(nodeID);
    NSParameterAssert(name);
    NSParameterAssert(interceptor);
    self = [super init];
    if (self) {
        _nodeID = nodeID;
        _name = name;
        _interceptor = interceptor;
    }
    return self;
}

+ (NSDictionary<NSString *, SANodeObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSURL *url = [bundle URLForResource:kSANodeFileName withExtension:@"json"];
    if (!url) {
        return nil;
    }
    NSArray *array = [SAJSONUtil JSONObjectWithData:[NSData dataWithContentsOfURL:url]];
    return [self loadFromResources:array];
}

+ (NSDictionary<NSString *, SANodeObject *> *)loadFromResources:(NSArray *)array {
    NSMutableDictionary *nodes = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        SANodeObject *node = [[SANodeObject alloc] initWithDictionary:dic];
        nodes[node.nodeID] = node;
    }
    return nodes;
}

@end
