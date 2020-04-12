//
//  SAObjectSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2019 Sensors Data Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "NSInvocation+SAHelpers.h"
#import "SAClassDescription.h"
#import "SAEnumDescription.h"
#import "SALog.h"
#import "SAObjectIdentityProvider.h"
#import "SAVisualizedAutoTrackObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAObjectSerializerContext.h"
#import "SAPropertyDescription.h"
#import "UIView+VisualizedAutoTrack.h"
#import "SAAutoTrackUtils.h"

@interface SAVisualizedAutoTrackObjectSerializer ()
@end

@implementation SAVisualizedAutoTrackObjectSerializer {
    SAObjectSerializerConfig *_configuration;
    SAObjectIdentityProvider *_objectIdentityProvider;
    BOOL isContainWebView;
}

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
               objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
        isContainWebView = NO;
    }
    
    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject {
    NSParameterAssert(rootObject != nil);
    
    SAObjectSerializerContext *context = [[SAObjectSerializerContext alloc] initWithRootObject:rootObject];
    
    @try {// 遍历 _unvisitedObjects 中所有元素，解析元素信息
        while ([context hasUnvisitedObjects]) {
            [self visitObject:[context dequeueUnvisitedObject] withContext:context];
        }
    } @catch (NSException *e) {
        SALogError(@"Failed to serialize objects: %@", e);
    }
    
    NSMutableDictionary *serializedObjects = [NSMutableDictionary dictionaryWithDictionary:@{
        @"objects" : [context allSerializedObjects],
        @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    }];
    serializedObjects[@"is_webview"] = @(isContainWebView);
    return [serializedObjects copy];
}

- (void)visitObject:(NSObject *)object withContext:(SAObjectSerializerContext *)context {
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);

    [context addVisitedObject:object];

    // 获取构建单个元素的所有属性
    NSMutableDictionary *propertyValues = [[NSMutableDictionary alloc] init];

    // 获取当前类以及父类页面结构需要的 name,superclass、properties
    SAClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        // 遍历自身和父类的所需的属性及类型，合并为当前类所有属性
        for (SAPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                //  根据是否符号要求（是否显示等）构建属性，通过 KVC 和 NSInvocation 动态调用获取描述信息
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context]; // $递增作为元素 id
                propertyValues[propertyDescription.key] = propertyValue ?: [NSNull null];
            }
        }
    }

    if (
#ifdef SENSORS_ANALYTICS_DISABLE_UIWEBVIEW
        [NSStringFromClass(object.class) isEqualToString:@"UIWebView"] ||
#else
        [object isKindOfClass:UIWebView.class] ||
#endif
        [object isKindOfClass:WKWebView.class]) {
            isContainWebView = YES;
        }

    propertyValues[@"isFromH5"] = @(NO);
    propertyValues[@"element_level"] = @([context currentLevelIndex]);
    NSDictionary *serializedObject = @{@"id": [_objectIdentityProvider identifierForObject:object],
                                       @"class": [self classHierarchyArrayForObject:object],  // 遍历获取父类名称
                                       @"properties": propertyValues};

    [context addSerializedObject:serializedObject];
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object {
    NSMutableArray *classHierarchy = [[NSMutableArray alloc] init];
    
    Class aClass = [object class];
    while (aClass) {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }
    return [classHierarchy copy];
}

- (NSInvocation *)invocationForObject:(id)object
              withSelectorDescription:(SAPropertySelectorDescription *)selectorDescription {
    
    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");
    
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;
    
    if (methodSignature) {
        NSAssert([methodSignature numberOfArguments] == 2, @"Unexpected number of arguments!");
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue
propertyDescription:(SAPropertyDescription *)propertyDescription
           context : (SAObjectSerializerContext *)context {
    
    if ([context isVisitedObject:propertyValue]) {
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([self isNestedObjectType:propertyDescription.type]) {
        [context enqueueUnvisitedObject:propertyValue];
        return [_objectIdentityProvider identifierForObject:propertyValue];
    }

    if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]) {
        NSMutableArray *arrayOfIdentifiers = [[NSMutableArray alloc] init];
        if ([propertyValue isKindOfClass:[NSArray class]]) {
            [context enqueueUnvisitedObjects:propertyValue];
        } else if ([propertyValue isKindOfClass:[NSSet class]]) {
            [context enqueueUnvisitedObjects:[(NSSet *)propertyValue allObjects]];
        }

        for (id value in propertyValue) {
            [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
        }
        propertyValue = [arrayOfIdentifiers copy];
    }

    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object
     withPropertyDescription:(SAPropertyDescription *)propertyDescription
                    context : (SAObjectSerializerContext *)context {
    SAPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;
    
    // 使用 kvc 解析属性
    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        
        id valueForKey = [object valueForKey:selectorDescription.selectorName];
        
        // 将获取到的属性属于 classes 中的元素添加到 _unvisitedObjects 中，递增生成当前元素唯一 Id
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];
        
        return value;
    } else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        
        // 通过 NSInvocation 构造并动态调用 selector，获取元素描述信息
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            [invocation sa_setArgumentsFromArray:@[]];
            [invocation invokeWithTarget:object];
            
            id returnValue = [invocation sa_returnValue];
            
            if ([object isKindOfClass:[UICollectionView class]]) {
                NSString *name = propertyDescription.name;
                if ([name isEqualToString:@"sensorsdata_subElements"]) {
                    @try {
                        NSArray *result = [returnValue sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {

                            if (obj2.frame.origin.y > obj1.frame.origin.y || obj2.frame.origin.x > obj1.frame.origin.x) {
                                return NSOrderedDescending;
                            }
                            return NSOrderedAscending;
                        }];
                        returnValue = [result copy];
                    } @catch (NSException *exception) {
                        SALogError(@"Failed to sensorsdata_subElements for UICollectionView sorted: %@", exception);
                    }
                }
            }
            
            id value = [self propertyValue:returnValue
                       propertyDescription:propertyDescription
                                   context:context];
            if (value) {
                return value;
            }
        }
    }
    return nil;
}

- (BOOL)isNestedObjectType:(NSString *)typeName {
    return [_configuration classWithName:typeName] != nil;
}

- (SAClassDescription *)classDescriptionForObject:(NSObject *)object {
    NSParameterAssert(object != nil);
    
    Class aClass = [object class];
    while (aClass != nil) {
        SAClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];
        if (classDescription) {
            return classDescription;
        }
        
        aClass = [aClass superclass];
    }
    
    return nil;
}

@end
