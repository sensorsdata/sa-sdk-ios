//
//  SAObjectSerializer.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "NSInvocation+SAHelpers.h"
#import "SAClassDescription.h"
#import "SAEnumDescription.h"
#import "SALog.h"
#import "SAObjectIdentityProvider.h"
#import "SAHeatMapObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAObjectSerializerContext.h"
#import "SAPropertyDescription.h"
#import "UIView+HeatMap.h"

@interface SAHeatMapObjectSerializer ()

@end

@implementation SAHeatMapObjectSerializer {
    SAObjectSerializerConfig *_configuration;
    SAObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(SAObjectSerializerConfig *)configuration
               objectIdentityProvider:(SAObjectIdentityProvider *)objectIdentityProvider {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }
    
    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject {
    NSParameterAssert(rootObject != nil);
    
    SAObjectSerializerContext *context = [[SAObjectSerializerContext alloc] initWithRootObject:rootObject];
    
    @try {
        while ([context hasUnvisitedObjects]) {
            [self visitObject:[context dequeueUnvisitedObject] withContext:context];
        }
    } @catch (NSException *e) {
        SALogError(@"Failed to serialize objects: %@", e);
    }
    
    return @{
        @"objects" : [context allSerializedObjects],
        @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    };
}

- (void)visitObject:(NSObject *)object withContext:(SAObjectSerializerContext *)context {
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);
    
    [context addVisitedObject:object];
    
    NSMutableDictionary *propertyValues = [[NSMutableDictionary alloc] init];
    
    SAClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        for (SAPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];
                propertyValues[propertyDescription.name] = propertyValue ?: [NSNull null];
            }
        }
    }
    
    id delegate;
    SEL delegateSelector = NSSelectorFromString(@"delegate");
    if ([object respondsToSelector:delegateSelector]) {
        delegate = ((id (*)(id, SEL))[object methodForSelector:delegateSelector])(object, delegateSelector);
    }
    
    NSDictionary *serializedObject = @{@"id": [_objectIdentityProvider identifierForObject:object],
                                       @"class": [self classHierarchyArrayForObject:object],
                                       @"properties": propertyValues,
                                       @"delegate": @{
                                               // BlockKit 等库使用 NSProxy 作 delegate 转发可能重写了 - (Class)class。
                                               @"class": delegate ? [NSString stringWithFormat:@"%@",[delegate class]] : @""}};
    
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

- (NSArray *)allValuesForType:(NSString *)typeName {
    NSParameterAssert(typeName != nil);
    
    SATypeDescription *typeDescription = [_configuration typeWithName:typeName];
    if ([typeDescription isKindOfClass:[SAEnumDescription class]]) {
        SAEnumDescription *enumDescription = (SAEnumDescription *)typeDescription;
        return [enumDescription allValues];
    }
    
    return @[];
}

- (NSArray *)parameterVariationsForPropertySelector:(SAPropertySelectorDescription *)selectorDescription {
    //    NSAssert([selectorDescription.parameters count] <= 1, @"Currently only support selectors that take 0 to 1 arguments.");
    
    NSMutableArray *variations = [[NSMutableArray alloc] init];
    
    [variations addObject:@[]];
    //    }
    
    return [variations copy];
}

- (NSInvocation *)invocationForObject:(id)object
              withSelectorDescription:(SAPropertySelectorDescription *)selectorDescription {
    NSUInteger __unused parameterCount = 0;
    
    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");
    
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;
    
    if (methodSignature) {
        NSAssert([methodSignature numberOfArguments] == (parameterCount + 2), @"Unexpected number of arguments!");
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue
propertyDescription:(SAPropertyDescription *)propertyDescription
            context: (SAObjectSerializerContext *)context {
    if (propertyValue != nil) {
        if ([context isVisitedObject:propertyValue]) {
            return [_objectIdentityProvider identifierForObject:propertyValue];
        } else if ([self isNestedObjectType:propertyDescription.type]) {
            [context enqueueUnvisitedObject:propertyValue];
            return [_objectIdentityProvider identifierForObject:propertyValue];
        } else if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]]) {
            NSMutableArray *arrayOfIdentifiers = [[NSMutableArray alloc] init];
            for (id value in propertyValue) {
                if ([context isVisitedObject:value] == NO) {
                    [context enqueueUnvisitedObject:value];
                }
                
                [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
            }
            propertyValue = [arrayOfIdentifiers copy];
        }
    }
    
    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object
     withPropertyDescription:(SAPropertyDescription *)propertyDescription
                     context:(SAObjectSerializerContext *)context {
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    
    SAPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;
    
    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        id valueForKey = [object valueForKey:selectorDescription.selectorName];
        
        if ([object isKindOfClass:[UICollectionView class]]) {
            NSString *name = propertyDescription.name;
            if ([name isEqualToString:@"subviews"]) {
                @try {
                    NSArray *result;
                    result = [valueForKey sortedArrayUsingComparator:^NSComparisonResult(UIView *obj1, UIView *obj2) {
                        if (obj2.frame.origin.y > obj1.frame.origin.y) {
                            return NSOrderedDescending;
                        }
                        if (obj2.frame.origin.x > obj1.frame.origin.x) {
                            return NSOrderedDescending;
                        } else {
                            return NSOrderedAscending;
                        }
                    }];
                    valueForKey = [result copy];
                    //valueForKey =  [[valueForKey reverseObjectEnumerator] allObjects];
                } @catch (NSException *exception) {
                    
                }
            }
        }
        
        if ([object isKindOfClass:[UITableView class]] || [object isKindOfClass:[UICollectionView class]]) {
            NSString *name = propertyDescription.name;
            if ([name isEqualToString:@"subviews"]) {
                valueForKey =  [[valueForKey reverseObjectEnumerator] allObjects];
            }
        }
        
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];
        
        NSDictionary *valueDictionary = @{
            @"value" : (value ?: [NSNull null])
        };
        
        [values addObject:valueDictionary];
    }  else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            NSArray *parameterVariations = [self parameterVariationsForPropertySelector:selectorDescription];
            
            for (NSArray *parameters in parameterVariations) {
                [invocation sa_setArgumentsFromArray:parameters];
                [invocation invokeWithTarget:object];
                
                id returnValue = [invocation sa_returnValue];
                
                id value = [self propertyValue:returnValue
                           propertyDescription:propertyDescription
                                       context:context];
                
                NSDictionary *valueDictionary = @{
                    @"where": @{ @"parameters" : parameters },
                    @"value": (value ?: [NSNull null])
                };
                
                [values addObject:valueDictionary];
            }
        }
    }
    
    return @{@"values": values};
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
