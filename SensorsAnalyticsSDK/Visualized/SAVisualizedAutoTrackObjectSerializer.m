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
#import "SALog.h"
#import "SAObjectIdentityProvider.h"
#import "SAVisualizedAutoTrackObjectSerializer.h"
#import "SAObjectSerializerConfig.h"
#import "SAObjectSerializerContext.h"
#import "SAPropertyDescription.h"
#import "UIView+SAElementPath.h"
#import "SAAutoTrackProperty.h"
#import "SAJSTouchEventView.h"
#import "SAVisualizedObjectSerializerManger.h"
#import "SAVisualizedManager.h"


@interface SAVisualizedAutoTrackObjectSerializer ()
@end

@implementation SAVisualizedAutoTrackObjectSerializer {
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
    if (!rootObject) {
        return nil;
    }

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
            //  根据是否符号要求（是否显示等）构建属性，通过 KVC 和 NSInvocation 动态调用获取描述信息
            id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];         // $递增作为元素 id
            propertyValues[propertyDescription.key] = propertyValue;
        }
    }

    if ([object isKindOfClass:WKWebView.class]) {
        // 针对 WKWebView 数据检查
        WKWebView *webView = (WKWebView *)object;
        [self checkWKWebViewInfoWithWebView:webView];
    } else {
        SEL isWebViewSEL = NSSelectorFromString(@"isWebViewWithObject:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:isWebViewSEL] && [self performSelector:isWebViewSEL withObject:object]) {
#pragma clang diagnostic pop
            // 暂不支持非 WKWebView，添加弹框
            [self addNotWKWebViewAlertInfo];
        }
    }

    NSArray *classNames = [self classHierarchyArrayForObject:object];
    if ([object isKindOfClass:SAJSTouchEventView.class]) {
        SAJSTouchEventView *touchView = (SAJSTouchEventView *)object;
        classNames = @[touchView.tagName];
    }

    propertyValues[@"element_level"] = @([context currentLevelIndex]);
    NSDictionary *serializedObject = @{ @"id": [_objectIdentityProvider identifierForObject:object],
                                        @"class": classNames, // 遍历获取父类名称
                                        @"properties": propertyValues };

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
            context:(SAObjectSerializerContext *)context {
    
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
                     context:(SAObjectSerializerContext *)context {
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

#pragma mark webview

/// 添加弹框信息
- (void)addNotWKWebViewAlertInfo {
    [[SAVisualizedObjectSerializerManger sharedInstance] enterWebViewPageWithWebInfo:nil];

    NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
    alertInfo[@"title"] = @"当前页面无法进行可视化全埋点";
    alertInfo[@"message"] = @"此页面不是 WKWebView，iOS App 内嵌 H5 可视化全埋点，只支持 WKWebView";
    alertInfo[@"link_text"] = @"配置文档";
    alertInfo[@"link_url"] = @"https://manual.sensorsdata.cn/sa/latest/enable_visualized_autotrack-7548675.html";
    if ([SAVisualizedManager sharedInstance].visualizedType == SensorsAnalyticsVisualizedTypeHeatMap) {
        alertInfo[@"title"] = @"当前页面无法进行点击分析";
        alertInfo[@"message"] = @"此页面包含 UIWebView，iOS App 内嵌 H5 点击分析，只支持 WKWebView";
        alertInfo[@"link_url"] = @"https://manual.sensorsdata.cn/sa/latest/app-16286049.html";
    }
    [[SAVisualizedObjectSerializerManger sharedInstance] registWebAlertInfos:@[alertInfo]];
}

/// 检查 WKWebView 相关信息
- (void)checkWKWebViewInfoWithWebView:(WKWebView *)webView {
    SAVisualizedWebPageInfo *webPageInfo = [[SAVisualizedObjectSerializerManger sharedInstance] readWebPageInfoWithWebView:webView];

    // H5 弹框信息
    if (webPageInfo.alertSources) {
        [[SAVisualizedObjectSerializerManger sharedInstance] registWebAlertInfos:webPageInfo.alertSources];
    }

    // H5 页面元素信息
    if (webPageInfo) {
        [[SAVisualizedObjectSerializerManger sharedInstance] enterWebViewPageWithWebInfo:webPageInfo];

        // 如果包含 H5 页面信息，不需要动态通知和 JS SDK 检测
        return;
    }

    // 当前 WKWebView 是否注入可视化全埋点 Bridge 标记
    WKUserContentController *contentController = webView.configuration.userContentController;
    NSArray<WKUserScript *> *userScripts = contentController.userScripts;
    // 防止重复注入标记（js 发送数据，是异步的，防止 sensorsdata_visualized_mode 已经注入完成，但是尚未接收到 js 数据）
    __block BOOL isContainVisualized = NO;
    [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj.source containsString:@"sensorsdata_visualized_mode"]) {
            isContainVisualized = YES;
            *stop = YES;
        }
    }];

    // 注入 bridge 属性值，标记当前处于可视化全埋点调试
    NSMutableString *javaScriptSource = [NSMutableString string];
    if (!isContainVisualized) {
        [javaScriptSource appendString:@"window.SensorsData_App_Visual_Bridge.sensorsdata_visualized_mode = true;"];
    }
    // 可能延迟开启可视化全埋点，未成功注入标记，通过调用 JS 方法，手动通知 JS SDK 发送数据
    [javaScriptSource appendString:@"window.sensorsdata_app_call_js('visualized')"];
    [webView evaluateJavaScript:javaScriptSource completionHandler:^(id _Nullable response, NSError *_Nullable error) {
        if (error) {
            /*
             如果 JS SDK 尚未加载完成，可能方法不存在；
             等到 JS SDK加载完成检测到 sensorsdata_visualized_mode 会尝试发送数据页面数据
             */
            SALogError(@"window.sensorsdata_app_call_js error：%@", error);
        }
    }];

    // 只有包含可视化全埋点 Bridge 标记，才可能需要检测 JS SDK 集成情况
    if (!isContainVisualized) {
        return;
    }

    // 延时检测是否集成 JS SDK
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 延迟判断是否存在 js 发送数据
        SAVisualizedWebPageInfo *currentWebPageInfo = [[SAVisualizedObjectSerializerManger sharedInstance] readWebPageInfoWithWebView:webView];
        // 注入了 bridge 但是未接收到数据
        if (!currentWebPageInfo) {
            NSString *javaScript = @"window.sensorsdata_app_call_js('sensorsdata-check-jssdk')";
            [webView evaluateJavaScript:javaScript completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                if (error) {
                    NSDictionary *userInfo = error.userInfo;
                    NSString *exceptionMessage = userInfo[@"WKJavaScriptExceptionMessage"];
                    // js 环境未定义此方法，可能是未集成 JS SDK 或者 JS SDK 版本过低
                    if (exceptionMessage && [exceptionMessage containsString:@"undefined is not a function"]) {
                        NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
                        alertInfo[@"title"] = @"当前页面无法进行可视化全埋点";
                        alertInfo[@"message"] = @"此页面未集成 Web JS SDK 或者 Web JS SDK 版本过低，请集成最新版 Web JS SDK";
                        alertInfo[@"link_text"] = @"配置文档";
                        alertInfo[@"link_url"] = @"https://manual.sensorsdata.cn/sa/latest/tech_sdk_client_web_use-7548173.html";
                        if ([SAVisualizedManager sharedInstance].visualizedType == SensorsAnalyticsVisualizedTypeHeatMap) {
                            alertInfo[@"title"] = @"当前页面无法进行点击分析";
                        }
                        NSDictionary *alertInfoMessage = @{ @"callType": @"app_alert", @"data": @[alertInfo] };
                        [[SAVisualizedObjectSerializerManger sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo:alertInfoMessage];
                    }
                }
            }];
        }
    });
}

@end
