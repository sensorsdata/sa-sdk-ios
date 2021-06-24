//
// SAVisualPropertiesTracker.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2021 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAVisualPropertiesTracker.h"
#import <UIKit/UIKit.h>
#import "SAVisualPropertiesConfigSources.h"
#import "SAVisualizedUtils.h"
#import "UIView+AutoTrack.h"
#import "UIView+SAElementPath.h"
#import "SAViewNodeTree.h"
#import "SACommonUtility.h"
#import "SAVisualizedDebugLogTracker.h"
#import "SAVisualizedLogger.h"
#import "SAAlertController.h"
#import "SAAutoTrackUtils.h"
#import "UIView+SAVisualProperties.h"
#import "SALog.h"

@interface SAVisualPropertiesTracker()

@property (atomic, strong) SAViewNodeTree *viewNodeTree;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) SAVisualPropertiesConfigSources *configSources;
@property (nonatomic, strong) SAVisualizedDebugLogTracker *debugLogTracker;
@property (nonatomic, strong) SAAlertController *enableLogAlertController;
@end

@implementation SAVisualPropertiesTracker

- (instancetype)initWithConfigSources:(SAVisualPropertiesConfigSources *)configSources {
    self = [super init];
    if (self) {
        _configSources = configSources;
        NSString *serialQueueLabel = [NSString stringWithFormat:@"com.sensorsdata.SAVisualPropertiesTracker.%p", self];
        _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        _viewNodeTree = [[SAViewNodeTree alloc] initWithQueue:_serialQueue];
    }
    return self;
}

#pragma mark build ViewNodeTree
- (void)didMoveToSuperviewWithView:(UIView *)view {
    /*节点更新和属性遍历，共用同一个队列
     防止触发点击事件，同时进行页面跳转，尚未遍历结束节点元素就被移除了
     */
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didMoveToSuperviewWithView:view];
    });
}

- (void)didMoveToWindowWithView:(UIView *)view {
    /*节点更新和属性遍历，共用同一个队列
     防止触发点击事件，同时进行页面跳转，尚未遍历结束节点元素就被移除了
     */
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didMoveToWindowWithView:view];
    });
}

- (void)didAddSubview:(UIView *)subview {
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didAddSubview:subview];
    });
}

- (void)becomeKeyWindow:(UIWindow *)window {
    if (!window.isKeyWindow) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree becomeKeyWindow:window];
    });
}

- (void)enterRNViewController:(UIViewController *)viewController {
    [self.viewNodeTree refreshRNViewScreenNameWithViewController:viewController];
}

#pragma mark visualProperties

// 采集元素自定义属性
- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler {
    
    /* 子线程执行
     1. 根据当前 view 查询事件配置
     2. 如果命中事件配置，根据当前事件配置，遍历包含的属性配置
     3. 根据属性配置和对应 path 等信息，查找对应的属性元素
     4. 从元素中，根据解析规则，解析对应的属性，拼接属性即可
     */
    // 如果列表定义事件不限定元素位置，则只能在当前列表内元素（点击元素所在位置）添加属性。所以此时的属性元素位置，和点击元素位置必须相同
    NSString *clickPosition = [view sensorsdata_elementPosition];
    
    NSInteger pageIndex = [SAVisualizedUtils pageIndexWithView:view];
    dispatch_async(self.serialQueue, ^{
        /* 添加日志信息
         在队列执行，防止快速点击导致的顺序错乱
         */
        if (self.debugLogTracker) {
            [self.debugLogTracker addTrackEventWithView:view withConfig:self.configSources.originalResponse];
        }
        
        /* 查询事件配置
         因为涉及是否限定位置，一个 view 可能被定义多个事件
         */
        SAViewNode *viewNode = view.sensorsdata_viewNode;
        NSArray <SAVisualPropertiesConfig *>*allEventConfigs = [self.configSources propertiesConfigsWithViewNode:viewNode];
        NSMutableDictionary *allEventProperties = [NSMutableDictionary dictionary];
        
        for (SAVisualPropertiesConfig *config in allEventConfigs) {
            // 查询属性
            NSDictionary *properties = [self queryAllPropertiesWithPropertiesConfig:config clickPosition:clickPosition pageIndex:pageIndex];
            if (properties.count > 0) {
                [allEventProperties addEntriesFromDictionary:properties];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(allEventProperties.count > 0 ? allEventProperties : nil);
        });
    });
}

/// 根据配置查询元素属性信息
/// @param config 配置信息
/// @param clickPosition 点击元素位置
/// @param pageIndex 页面序号
- (nullable NSDictionary *)queryAllPropertiesWithPropertiesConfig:(SAVisualPropertiesConfig *)config clickPosition:(NSString *)clickPosition pageIndex:(NSInteger)pageIndex {

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    for (SAVisualPropertiesPropertyConfig *propertyConfig in config.properties) {
        // 合法性校验
        if (propertyConfig.regular.length == 0 || propertyConfig.name.length == 0 || propertyConfig.elementPath.length == 0) {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"属性配置" message:@"属性 %@ 无效", propertyConfig];
            SALogError(@"SAVisualPropertiesPropertyConfig error, %@", logMessage);
            continue;
        }
        
        // 事件是否限定元素位置，影响属性元素的匹配逻辑
        propertyConfig.limitPosition = config.event.limitPosition;
        
        /* 属性配置，保存点击位置
         属性配置中保存当前点击元素位置，用于属性元素筛选
         如果属性元素为当前点击 Cell 嵌套 Cell 的内嵌元素，则不需使用当前位置匹配
         路径示例如下：
         Cell 本身路径：UIView/UITableView[0]/SACommonTableViewCell[0][-]
         Cell 嵌套普通元素路径：UIView/UITableView[0]/SACommonTableViewCell[0][-]/UITableViewCellContentView[0]/UIButton[0]
         Cell 嵌套 Cell 路径：UIView/UITableView[1]/TableViewCollectionViewCell[0][0]/UITableViewCellContentView[0]/UICollectionView[0]/HomeOptionsCollecionCell[0][-]
         Cell 嵌套 Cell 再嵌套元素路径：UIView/UITableView[1]/TableViewCollectionViewCell[0][0]/UITableViewCellContentView[0]/UICollectionView[0]/HomeOptionsCollecionCell[0][-]/UIView[0]/UIView[0]/UIButton[0]
         
         备注: cell 内嵌 button 的点击事件，那么 cell 内嵌 其他 view，也支持这种不限定位置的约束和筛选逻辑，path 示例如下:
         UIView/UITableView[0]/SATestTableViewCell[0][-]/UITableViewCellContentView[0]/UIStackView[0]/UIButton[1]
         UIView/UITableView[0]/SATestTableViewCell[0][-]/UITableViewCellContentView[0]/UIStackView[0]/UILabel[0]
         */
        
        NSRange propertyRange = [propertyConfig.elementPath rangeOfString:@"[-]"];
        NSRange eventRange = [config.event.elementPath rangeOfString:@"[-]"];
        
        if (propertyRange.location != NSNotFound && eventRange.location != NSNotFound) {
            NSString *propertyElementPathPrefix = [propertyConfig.elementPath substringToIndex:propertyRange.location];
            NSString *eventElementPathPrefix = [config.event.elementPath substringToIndex:eventRange.location];
            if ([propertyElementPathPrefix isEqualToString:eventElementPathPrefix]) {
                propertyConfig.clickElementPosition = clickPosition;
            }
        }

        // 页面序号，仅匹配当前页面元素
        propertyConfig.pageIndex = pageIndex;

        // 1. 获取属性元素
        UIView *view = [self.viewNodeTree viewWithPropertyConfig:propertyConfig];
        if (!view) {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"获取属性元素" message:@"属性 %@ 未找到对应属性元素", propertyConfig.name];
            SALogDebug(@"%@", logMessage);
            continue;
        }
        
        // 2. 根据属性元素，解析属性值
        NSString *propertyValue = [self analysisPropertyWithView:view propertyConfig:propertyConfig];
        if (!propertyValue) {
            continue;
        }

        // 3. 属性类型转换
        // 字符型属性
        if (propertyConfig.type == SAVisualPropertyTypeString) {
            properties[propertyConfig.name] = propertyValue;
            continue;
        }

        // 数值型属性
        NSDecimalNumber *propertyNumber = [NSDecimalNumber decimalNumberWithString:propertyValue];
        // 判断转换后是否为 NAN
        if ([propertyNumber isEqualToNumber:NSDecimalNumber.notANumber]) {
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"属性 %@ 正则解析后为：%@，数值型转换失败", propertyConfig.name, propertyValue];
            SALogWarn(@"%@", logMessage);
            continue;
        }

        properties[propertyConfig.name] = propertyNumber;
    }
    return properties;
}

/// 解析属性值
- (NSString *)analysisPropertyWithView:(UIView *)view propertyConfig:(SAVisualPropertiesPropertyConfig *)config {
    
    // 获取元素内容，主线程执行
    __block NSString *content = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        content = view.sensorsdata_elementContent;
    });
    
    if (content.length == 0) {
        // 打印 view 需要在主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"属性 %@ 获取元素内容失败, %@", config.name, view];
            SALogWarn(@"%@", logMessage);
        });
        return nil;
    }
    
    // 根据正则解析属性
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:config.regular options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    
    // 仅取出第一条匹配记录
    NSTextCheckingResult *firstResult = [regex firstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
    if (!firstResult) {
        NSString *logMessage = [SAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"元素内容 %@ 正则解析属性失败，属性名：%@，正则为：%@", content,  config.name, config.regular];
        SALogWarn(@"%@", logMessage);
        return nil;
    }
    
    NSString *value = [content substringWithRange:firstResult.range];
    return value;
}

#pragma mark - logInfos
/// 开始采集调试日志
- (void)enableCollectDebugLog:(BOOL)enable {
    if (!enable) { // 关闭日志采集
        self.debugLogTracker = nil;
        self.enableLogAlertController = nil;
        return;
    }
    // 已经开启日志采集
    if (self.debugLogTracker) {
        return;
    }
    
    // 开启日志采集
    if (SensorsAnalyticsSDK.sharedInstance.configOptions.enableLog) {
        self.debugLogTracker = [[SAVisualizedDebugLogTracker alloc] init];
        return;
    }
    
    // 避免重复弹框
    if (self.enableLogAlertController) {
        return;
    }
    // 未开启 enableLog，弹框提示
    __weak SAVisualPropertiesTracker *weakSelf = self;
    self.enableLogAlertController = [[SAAlertController alloc] initWithTitle:@"提示" message:@"可视化全埋点进入 Debug 模式，需要开启日志打印用于收集调试信息，退出 Debug 模式关闭日志打印，是否需要开启呢？" preferredStyle:SAAlertControllerStyleAlert];
    [self.enableLogAlertController addActionWithTitle:@"开启日志打印" style:SAAlertActionStyleDefault handler:^(SAAlertAction * _Nonnull action) {
        [[SensorsAnalyticsSDK sharedInstance] enableLog:YES];
        
        weakSelf.debugLogTracker = [[SAVisualizedDebugLogTracker alloc] init];
    }];
    [self.enableLogAlertController addActionWithTitle:@"暂不开启" style:SAAlertActionStyleCancel handler:nil];
    [self.enableLogAlertController show];
}

- (NSArray<NSDictionary *> *)logInfos {
    return [self.debugLogTracker.debugLogInfos copy];
}

@end


