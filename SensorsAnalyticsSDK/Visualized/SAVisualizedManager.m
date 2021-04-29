//
// SAVisualizedManager.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/12/25.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAVisualizedManager.h"
#import "SAVisualizedConnection.h"
#import "SAAlertController.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SensorsAnalyticsSDK+Visualized.h"
#import "UIViewController+SAElementPath.h"
#import "SAVisualPropertiesConfigSources.h"
#import "SAConstants+Private.h"
#import "UIView+SAElementPath.h"
#import "UIView+AutoTrack.h"
#import "SAVisualizedUtils.h"
#import "SAModuleManager.h"
#import "SAReachability.h"
#import "SAURLUtils.h"
#import "SASwizzle.h"
#import "SALog.h"

static void * const kSAVisualizeContext = (void*)&kSAVisualizeContext;
static NSString * const kSAVisualizeObserverKeyPath = @"serverURL";

@interface SAVisualizedManager()<SAConfigChangesDelegate>

@property (nonatomic, strong) SAVisualizedConnection *visualizedConnection;

/// 当前类型
@property (nonatomic, assign) SensorsAnalyticsVisualizedType visualizedType;

/// 指定开启可视化的 viewControllers 名称
@property (nonatomic, strong) NSMutableSet<NSString *> *visualizedViewControllers;

/// 自定义属性采集
@property (nonatomic, strong) SAVisualPropertiesTracker *visualPropertiesTracker;

/// 获取远程配置
@property (nonatomic, strong, readwrite) SAVisualPropertiesConfigSources *configSources;

/// 埋点校验
@property (nonatomic, strong, readwrite) SAVisualizedEventCheck *eventCheck;
@end


@implementation SAVisualizedManager

+ (SAVisualizedManager *)sharedInstance {
    id <SAModuleProtocol>manager = [[SAModuleManager sharedInstance] managerForModuleType:SAModuleTypeVisualized];
    if (manager.isEnable) {
        return (SAVisualizedManager *)manager;
    }
    return nil;
}

#pragma mark initialize
- (instancetype)init {
    self = [super init];
    if (self) {
        _visualizedViewControllers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.configOptions removeObserver:self forKeyPath:kSAVisualizeObserverKeyPath context:kSAVisualizeContext];
}

#pragma mark SAConfigChangesDelegate
- (void)configChangedWithValid:(BOOL)valid {
    if (valid){
        if (!self.visualPropertiesTracker) {
            // 配置可用，开启自定义属性采集
            self.visualPropertiesTracker = [[SAVisualPropertiesTracker alloc] initWithConfigSources:self.configSources];
        }

        // 配置动态变化，开启埋点校验
        if (!self.eventCheck && self.visualizedType == SensorsAnalyticsVisualizedTypeAutoTrack) {
            self.eventCheck = [[SAVisualizedEventCheck alloc] initWithConfigSources:self.configSources];
        }
    } else {
        self.visualPropertiesTracker = nil;
        self.eventCheck = nil;
    }
}

#pragma mark -
- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (!enable) {
        self.configSources = nil;
        self.visualPropertiesTracker = nil;
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_visualize_viewDidAppear:) error:&error];
        if (error) {
            SALogError(@"Failed to swizzle on UIViewController. Details: %@", error);
        }

        // 监听 configOptions 中 serverURL 变化，更新属性配置
        if (self.configOptions.enableVisualizedAutoTrack) {
            [self.configOptions addObserver:self forKeyPath:kSAVisualizeObserverKeyPath options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:kSAVisualizeContext];
        }
    });

    if (!self.configSources && self.configOptions.enableVisualizedAutoTrack) {
        // 只要开启可视化，默认获取远程配置
        self.configSources = [[SAVisualPropertiesConfigSources alloc] initWithDelegate:self];
        [self.configSources loadConfig];
    }
}

#pragma mark - handle URL
- (BOOL)canHandleURL:(NSURL *)url {
    return [self isHeatMapURL:url] || [self isVisualizedAutoTrackURL:url];
}

// 待优化，拆分可视化和点击分析
- (BOOL)isHeatMapURL:(NSURL *)url {
    return [url.host isEqualToString:@"heatmap"];
}

- (BOOL)isVisualizedAutoTrackURL:(NSURL *)url {
    return [url.host isEqualToString:@"visualized"];
}

- (BOOL)handleURL:(NSURL *)url {
    if (![self canHandleURL:url]) {
        return NO;
    }

    NSDictionary *queryItems = [SAURLUtils decodeRueryItemsWithURL:url];
    NSString *featureCode = queryItems[@"feature_code"];
    NSString *postURLStr = queryItems[@"url"];

    // project 和 host 不同
    NSString *project = [SAURLUtils queryItemsWithURLString:postURLStr][@"project"] ?: @"default";
    BOOL isEqualProject = [[SensorsAnalyticsSDK sharedInstance].network.project isEqualToString:project];
    if (!isEqualProject) {
        if ([self isHeatMapURL:url]) {
            [SAVisualizedManager showAlterViewWithTitle:@"提示" message:@"App 集成的项目与电脑浏览器打开的项目不同，无法进行点击分析"];
        } else if([self isVisualizedAutoTrackURL:url]){
            [SAVisualizedManager showAlterViewWithTitle:@"提示" message:@"App 集成的项目与电脑浏览器打开的项目不同，无法进行可视化全埋点"];
        }
        return YES;
    }

    // 未开启点击图
    if ([url.host isEqualToString:@"heatmap"] && ![[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled]) {
        [SAVisualizedManager showAlterViewWithTitle:@"提示" message:@"SDK 没有被正确集成，请联系贵方技术人员开启点击分析"];
        return YES;
    }

    // 未开启可视化全埋点
    if ([url.host isEqualToString:@"visualized"] && ![[SensorsAnalyticsSDK sharedInstance] isVisualizedAutoTrackEnabled]) {
        [SAVisualizedManager showAlterViewWithTitle:@"提示" message:@"SDK 没有被正确集成，请联系贵方技术人员开启可视化全埋点"];
        return YES;
    }
    if (featureCode && postURLStr && self.isEnable) {
        [SAVisualizedManager.sharedInstance showOpenAlertWithURL:url featureCode:featureCode postURL:postURLStr];
        return YES;
    }
    //feature_code url 参数错误
    [SAVisualizedManager showAlterViewWithTitle:@"ERROR" message:@"参数错误"];
    return NO;
}

+ (void)showAlterViewWithTitle:(NSString *)title message:(NSString *)message {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:@"确认" style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
}

- (void)showOpenAlertWithURL:(NSURL *)URL featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    NSString *alertTitle = @"提示";
    NSString *alertMessage = [self alertMessageWithURL:URL];

    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];

    [alertController addActionWithTitle:@"取消" style:SAAlertActionStyleCancel handler:^(SAAlertAction *_Nonnull action) {
        [self.visualizedConnection close];
        self.visualizedConnection = nil;
    }];

    [alertController addActionWithTitle:@"继续" style:SAAlertActionStyleDefault handler:^(SAAlertAction *_Nonnull action) {
        // 关闭之前的连接
        [self.visualizedConnection close];
        // start
        self.visualizedConnection = [[SAVisualizedConnection alloc] init];
        if ([self isHeatMapURL:URL]) {
            SALogDebug(@"Confirmed to open HeatMap ...");
            self.visualizedType = SensorsAnalyticsVisualizedTypeHeatMap;
        } else if ([self isVisualizedAutoTrackURL:URL]) {
            SALogDebug(@"Confirmed to open VisualizedAutoTrack ...");
            self.visualizedType = SensorsAnalyticsVisualizedTypeAutoTrack;

            // 开启埋点校验
            [self enableEventCheck:YES];
        }
        [self.visualizedConnection startConnectionWithFeatureCode:featureCode url:postURL];
    }];

    [alertController show];
}

- (NSString *)alertMessageWithURL:(NSURL *)URL{
    NSString *alertMessage = nil;
    if ([self isHeatMapURL:URL]) {
        alertMessage = @"正在连接 App 点击分析";
    } else {
        alertMessage = @"正在连接 App 可视化全埋点";
    }

    if (![SAReachability sharedInstance].isReachableViaWiFi) {
        alertMessage = [alertMessage stringByAppendingString: @"，建议在 WiFi 环境下使用"];
    }
    return alertMessage;
}

/// 当前类型
- (SensorsAnalyticsVisualizedType)currentVisualizedType {
    return self.visualizedType;
}


#pragma mark - Visualize
- (BOOL)isConnecting {
    return self.visualizedConnection.isVisualizedConnecting;
}

- (void)addVisualizeWithViewControllers:(NSArray<NSString *> *)controllers {
    if (![controllers isKindOfClass:[NSArray class]] || controllers.count == 0) {
        return;
    }
    [self.visualizedViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isVisualizeWithViewController:(UIViewController *)viewController {
    if (!viewController) {
        return YES;
    }

    if (self.visualizedViewControllers.count == 0) {
        return YES;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [self.visualizedViewControllers containsObject:screenName];
}

#pragma mark - Property

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != kSAVisualizeContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

    if (![keyPath isEqualToString:kSAVisualizeObserverKeyPath] || [change[NSKeyValueChangeNewKey] isEqualToString:change[NSKeyValueChangeOldKey]]) {
        return;
    }

    // 更新配置信息
    [self.configSources reloadConfig];
}


- (nullable NSDictionary *)propertiesWithView:(UIView *)view {
    UIViewController<SAAutoTrackViewControllerProperty> *viewController = view.sensorsdata_viewController;
    if (!viewController) {
        return nil;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    if (self.visualizedViewControllers.count > 0 && ![self.visualizedViewControllers containsObject:screenName]) {
        return nil;
    }

    // 1 获取 viewPath 相关属性
    NSString *elementSelector = [SAVisualizedUtils viewPathForView:view atViewController:viewController];

    NSString *elementPath = [SAVisualizedUtils viewSimilarPathForView:view atViewController:viewController shouldSimilarPath:YES];
    
    NSMutableDictionary *viewPthProperties = [NSMutableDictionary dictionary];
    viewPthProperties[SA_EVENT_PROPERTY_ELEMENT_SELECTOR] = elementSelector;
    viewPthProperties[SA_EVENT_PROPERTY_ELEMENT_PATH] = elementPath;

    return viewPthProperties.count > 0 ? viewPthProperties : nil;
}

- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    if (!self.visualPropertiesTracker) {
        completionHandler(nil);
    }

    @try {
        [self.visualPropertiesTracker visualPropertiesWithView:view completionHandler:completionHandler];
    } @catch (NSException *exception) {
        SALogError(@"visualPropertiesWithView error: %@", exception);
        completionHandler(nil);
    }
}

#pragma mark - eventCheck
/// 是否开启埋点校验
- (void)enableEventCheck:(BOOL)enable {
    if (!enable) {
        self.eventCheck = nil;
        return;
    }

    // 配置可用才需开启埋点校验
    if (!self.eventCheck && self.configSources.isValid) {
        self.eventCheck = [[SAVisualizedEventCheck alloc] initWithConfigSources:self.configSources];
    }
}

@end
