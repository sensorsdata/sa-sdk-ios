//
// NSObject+SAKeyValueObserver.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2023/2/23.
// Copyright © 2015-2023 Sensors Data Co., Ltd. All rights reserved.
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

#import "NSObject+SAKeyValueObserver.h"
#import <objc/runtime.h>
#import "SALog.h"

static void *const kSAKVOObserverInfosKey = (void *)&kSAKVOObserverInfosKey;
static void *const kSAKVOTargetInfosKey = (void *)&kSAKVOTargetInfosKey;
static void *const kSAKVOObserversKey = (void *)&kSAKVOObserversKey;
static void *const kSAKVOTargetsKey = (void *)&kSAKVOTargetsKey;

@implementation SAKVOObject

- (instancetype)initWithKeyPath:(NSString *)keyPath context:(void *)context {
    if (self = [super init]) {
        _keyPath = keyPath;
        _context = [NSValue valueWithPointer:context];
    }
    return self;
}

@end

@implementation NSObject (SAKeyValueObserver)

- (void)setSensorsdata_KVO_observerInfos:(NSMutableDictionary *)sensorsdata_KVO_observerInfos {
    objc_setAssociatedObject(self, kSAKVOObserverInfosKey, sensorsdata_KVO_observerInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)sensorsdata_KVO_observerInfos {
    NSMutableDictionary *observerInfos = objc_getAssociatedObject(self, kSAKVOObserverInfosKey);
    if (!observerInfos) {
        observerInfos = [NSMutableDictionary dictionary];
        self.sensorsdata_KVO_observerInfos = observerInfos;
    }
    return observerInfos;
}

- (void)setSensorsdata_KVO_targetInfos:(NSMutableDictionary *)sensorsdata_KVO_targetInfos {
    objc_setAssociatedObject(self, kSAKVOTargetInfosKey, sensorsdata_KVO_targetInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)sensorsdata_KVO_targetInfos {
    NSMutableDictionary *targetInfos = objc_getAssociatedObject(self, kSAKVOTargetInfosKey);
    if (!targetInfos) {
        targetInfos = [NSMutableDictionary dictionary];
        self.sensorsdata_KVO_targetInfos = targetInfos;
    }
    return targetInfos;
}

- (void)setSensorsdata_KVO_observers:(NSHashTable * _Nullable)sensorsdata_KVO_observers {
    objc_setAssociatedObject(self, kSAKVOObserversKey, sensorsdata_KVO_observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_KVO_observers {
    return objc_getAssociatedObject(self, kSAKVOObserversKey);
}

- (void)setSensorsdata_KVO_targets:(NSHashTable * _Nullable)sensorsdata_KVO_targets {
    objc_setAssociatedObject(self, kSAKVOTargetsKey, sensorsdata_KVO_targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_KVO_targets {
    return objc_getAssociatedObject(self, kSAKVOTargetsKey);
}

- (void)sensorsdata_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    if (![self shouldAddObserver:observer forKeyPath:keyPath context:context]) {
        return;
    }
    [self addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (BOOL)shouldAddObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    if (!observer || !keyPath) {
        return NO;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSArray <SAKVOObject *>*observerInfos = self.sensorsdata_KVO_observerInfos[observerAddress];
    if (!observerInfos) {
        observerInfos = [NSArray array];
    }
    //filter observer infos to check if existed same observer info
    NSArray *existedObserverInfos = [observerInfos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        SAKVOObject *tempObserverInfo = evaluatedObject;
        NSString *tempKeyPath = tempObserverInfo.keyPath;
        NSValue *tempContext = tempObserverInfo.context;
        return  [tempKeyPath isEqualToString:keyPath] && [tempContext isEqualToValue:[NSValue valueWithPointer:context]];
    }]];
    if (existedObserverInfos.count > 0) {
        return NO;
    }
    //add observer and target info
    SAKVOObject *observerInfo = [[SAKVOObject alloc] initWithKeyPath:keyPath context:context];
    NSMutableArray <SAKVOObject *>*tempObserverInfos = [NSMutableArray arrayWithArray:observerInfos];
    [tempObserverInfos addObject:observerInfo];
    self.sensorsdata_KVO_observerInfos[observerAddress] = [tempObserverInfos copy];
    NSString *targetAddress = [NSString stringWithFormat:@"%p", self];
    NSArray <SAKVOObject *>*targetInfos = observer.sensorsdata_KVO_targetInfos[targetAddress];
    NSMutableArray <SAKVOObject *>*tempTargetInfos = [NSMutableArray array];
    if (targetInfos) {
        [tempTargetInfos addObjectsFromArray:targetInfos];
    }
    [tempTargetInfos addObject:observerInfo];
    observer.sensorsdata_KVO_targetInfos[targetAddress] = [tempTargetInfos copy];
    if (!self.sensorsdata_KVO_observers) {
        self.sensorsdata_KVO_observers = [NSHashTable weakObjectsHashTable];
    }
    if (!observer.sensorsdata_KVO_targets) {
        observer.sensorsdata_KVO_targets = [NSHashTable weakObjectsHashTable];
    }
    [self.sensorsdata_KVO_observers addObject:observer];
    [observer.sensorsdata_KVO_targets addObject:self];

    return YES;
}

- (void)removeKVOWhenDealloc {
    @try {
        [self removeKVOTargetsWhenDealloc];
        [self removeKVOObserversWhenDealloc];
    } @catch (NSException *exception) {
        SALogError(@"remove KVO exception: %@", exception);
    } @finally {
    }
}

- (void)removeKVOTargetsWhenDealloc {
    if (!self.sensorsdata_KVO_targets) {
        return;
    }
    for (NSObject *target in self.sensorsdata_KVO_targets) {
        NSString *targetAddress = [NSString stringWithFormat:@"%p", target];
        for (SAKVOObject *targetInfo in self.sensorsdata_KVO_targetInfos[targetAddress]) {
            [target removeObserver:self forKeyPath:targetInfo.keyPath context:targetInfo.context.pointerValue];
        }
    }
}

- (void)removeKVOObserversWhenDealloc {
    if (!self.sensorsdata_KVO_observers) {
        return;
    }
    for (NSObject *observer in self.sensorsdata_KVO_observers) {
        NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
        for (SAKVOObject *observerInfo in self.sensorsdata_KVO_observerInfos[observerAddress]) {
            [self removeObserver:observer forKeyPath:observerInfo.keyPath context:observerInfo.context.pointerValue];
        }
    }
}

- (void)sensorsdata_dealloc {
    //remove observer info
    [self removeKVOWhenDealloc];
    [self sensorsdata_dealloc];
}

@end
