//
// SAVisualizedManager.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2020/12/25.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAVisualizedManager.h"
#import "SAAlertController.h"
#import "UIViewController+SAElementPath.h"
#import "SAConstants+Private.h"
#import "UIView+SAAutoTrack.h"
#import "SAVisualizedUtils.h"
#import "SAModuleManager.h"
#import "SAJavaScriptBridgeManager.h"
#import "SAReachability.h"
#import "SAValidator.h"
#import "SAURLUtils.h"
#import "SAJSONUtil.h"
#import "SASwizzle.h"
#import "SALog.h"
#import "SAFlutterPluginBridge.h"
#import "UIView+SAInternalProperties.h"

@interface SAVisualizedManager()<SAConfigChangesDelegate>

@property (nonatomic, strong) SAVisualizedConnection *visualizedConnection;

/// 当前类型
@property (nonatomic, assign) SensorsAnalyticsVisualizedType visualizedType;

/// 指定开启可视化/点击分析的 viewControllers 名称
@property (nonatomic, strong) NSMutableSet<NSString *> *visualizedViewControllers;

/// 自定义属性采集
@property (nonatomic, strong) SAVisualPropertiesTracker *visualPropertiesTracker;

/// 获取远程配置
@property (nonatomic, strong) SAVisualPropertiesConfigSources *configSources;

/// 埋点校验
@property (nonatomic, strong) SAVisualizedEventCheck *eventCheck;

@end


@implementation SAVisualizedManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static SAVisualizedManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAVisualizedManager alloc] init];
    });
    return manager;
}

#pragma mark initialize
- (instancetype)init {
    self = [super init];
    if (self) {
        _visualizedViewControllers = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark SAConfigChangesDelegate
- (void)configChangedWithValid:(BOOL)valid {
    if (valid){
        if (!self.visualPropertiesTracker) {
            // 配置可用，开启自定义属性采集
            self.visualPropertiesTracker = [[SAVisualPropertiesTracker alloc] initWithConfigSources:self.configSources];
        }

        // 可能扫码阶段，可能尚未请求到配置，此处再次尝试开启埋点校验
        if (!self.eventCheck && self.visualizedType == SensorsAnalyticsVisualizedTypeAutoTrack) {
            self.eventCheck = [[SAVisualizedEventCheck alloc] initWithConfigSources:self.configSources];
        }

        // 配置更新，发送到 WKWebView 的内嵌 H5
        [self.visualPropertiesTracker.viewNodeTree updateConfig:self.configSources.originalResponse];

        // 配置更新，通知 Flutter
        [SAFlutterPluginBridge.sharedInstance changeVisualPropertiesConfig:self.configSources.originalResponse];

    } else {
        self.visualPropertiesTracker = nil;
        self.eventCheck = nil;
    }
}

#pragma mark -
- (void)setEnable:(BOOL)enable NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    _enable = enable;

    if (!enable) {
        self.configSources = nil;
        self.visualPropertiesTracker = nil;
        [self.visualizedConnection close];
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_visualize_viewDidAppear:) error:&error];
        if (error) {
            SALogError(@"Failed to swizzle on UIViewController. Details: %@", error);
        }
    });

    // 未开启自定义属性
    if (!self.configOptions.enableVisualizedProperties) {
        SALogDebug(@"Current App does not support visualizedProperties");
        return;
    }

    if (!self.configSources) {
        // 获取自定义属性配置
        self.configSources = [[SAVisualPropertiesConfigSources alloc] initWithDelegate:self];
        [self.configSources loadConfig];
    }
}

- (void)setConfigOptions:(SAConfigOptions *)configOptions NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    _configOptions = configOptions;

    // 由于自定义属性依赖于可视化全埋点，所以只要开启自定义属性，默认打开可视化全埋点相关功能
    // 可视化全埋点或点击分析开启
    self.enable = configOptions.enableHeatMap || configOptions.enableVisualizedAutoTrack || configOptions.enableVisualizedProperties;
}

-(void)updateServerURL:(NSString *)serverURL {
    if (![SAValidator isValidString:serverURL]) {
        return;
    }
    // 刷新自定义属性配置
    [self.configSources reloadConfig];
}

#pragma mark -
- (NSString *)javaScriptSource NS_EXTENSION_UNAVAILABLE("VisualizedAutoTrack not supported for iOS extensions.") {
    if (!self.enable) {
        return nil;
    }
    // App 内嵌 H5 数据交互
    NSMutableString *javaScriptSource = [NSMutableString string];
    if (self.visualizedConnection.isVisualizedConnecting) {
        NSString *jsVisualizedMode = [SAJavaScriptBridgeBuilder buildVisualBridgeWithVisualizedMode:YES];
        [javaScriptSource appendString:jsVisualizedMode];
    }

    if (!self.configOptions.enableVisualizedProperties || !self.configSources.isValid || self.configSources.originalResponse.count == 0) {
        return javaScriptSource;
    }

    // 注入完整配置信息
    NSString *webVisualConfig = [SAJavaScriptBridgeBuilder buildVisualPropertyBridgeWithVisualConfig:self.configSources.originalResponse];
    if (!webVisualConfig) {
        return javaScriptSource;
    }
    [javaScriptSource appendString:webVisualConfig];
    return javaScriptSource;
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

    NSDictionary *queryItems = [SAURLUtils decodeQueryItemsWithURL:url];
    NSString *featureCode = queryItems[@"feature_code"];
    NSString *postURLStr = queryItems[@"url"];

    // project 和 host 不同
    NSString *project = [SAURLUtils queryItemsWithURLString:postURLStr][@"project"] ?: @"default";
    BOOL isEqualProject = [[SensorsAnalyticsSDK sharedInstance].network.project isEqualToString:project];
    if (!isEqualProject) {
        if ([self isHeatMapURL:url]) {
            [SAVisualizedManager showAlterViewWithTitle:SALocalizedString(@"SAAlertHint") message:SALocalizedString(@"SAAppClicksAnalyticsProjectError")];
        } else if([self isVisualizedAutoTrackURL:url]){
            [SAVisualizedManager showAlterViewWithTitle:SALocalizedString(@"SAAlertHint") message:SALocalizedString(@"SAVisualizedProjectError")];
        }
        return YES;
    }

    // 未开启点击图
    if ([url.host isEqualToString:@"heatmap"] && ![[SensorsAnalyticsSDK sharedInstance] isHeatMapEnabled]) {
        [SAVisualizedManager showAlterViewWithTitle:SALocalizedString(@"SAAlertHint") message:SALocalizedString(@"SAAppClicksAnalyticsSDKError")];
        return YES;
    }

    // 未开启可视化全埋点
    if ([url.host isEqualToString:@"visualized"] && ![[SensorsAnalyticsSDK sharedInstance] isVisualizedAutoTrackEnabled]) {
        [SAVisualizedManager showAlterViewWithTitle:SALocalizedString(@"SAAlertHint") message:SALocalizedString(@"SAVisualizedSDKError")];
        
        return YES;
    }
    if (featureCode && postURLStr && self.isEnable) {
        [SAVisualizedManager.defaultManager showOpenAlertWithURL:url featureCode:featureCode postURL:postURLStr];
        return YES;
    }
    //feature_code url 参数错误
    [SAVisualizedManager showAlterViewWithTitle:@"ERROR" message:SALocalizedString(@"SAVisualizedParameterError")];
    return NO;
}

+ (void)showAlterViewWithTitle:(NSString *)title message:(NSString *)message {
    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:title message:message preferredStyle:SAAlertControllerStyleAlert];
    [alertController addActionWithTitle:SALocalizedString(@"SAAlertOK") style:SAAlertActionStyleDefault handler:nil];
    [alertController show];
}

- (void)showOpenAlertWithURL:(NSURL *)URL featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    NSString *alertTitle = SALocalizedString(@"SAAlertHint");
    NSString *alertMessage = [self alertMessageWithURL:URL];

    SAAlertController *alertController = [[SAAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:SAAlertControllerStyleAlert];

    [alertController addActionWithTitle:SALocalizedString(@"SAAlertCancel") style:SAAlertActionStyleCancel handler:^(SAAlertAction *_Nonnull action) {
        [self.visualizedConnection close];
        self.visualizedConnection = nil;
    }];

    [alertController addActionWithTitle:SALocalizedString(@"SAAlertContinue") style:SAAlertActionStyleDefault handler:^(SAAlertAction *_Nonnull action) {
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
        alertMessage = SALocalizedString(@"SAAppClicksAnalyticsConnect");
    } else {
        alertMessage = SALocalizedString(@"SAVisualizedConnect");
    }

    if (![SAReachability sharedInstance].isReachableViaWiFi) {
        alertMessage = [alertMessage stringByAppendingString:SALocalizedString(@"SAVisualizedWifi")];
    }
    return alertMessage;
}

#pragma mark - Visualize

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
- (nullable NSDictionary *)propertiesWithView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return nil;
    }
    UIViewController<SAUIViewControllerInternalProperties> *viewController = view.sensorsdata_viewController;
    if (!viewController) {
        return nil;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    if (self.visualizedViewControllers.count > 0 && ![self.visualizedViewControllers containsObject:screenName]) {
        return nil;
    }

    // 获取 viewPath 相关属性
    NSString *elementPath = [SAVisualizedUtils viewSimilarPathForView:view atViewController:viewController];
    
    NSMutableDictionary *viewPthProperties = [NSMutableDictionary dictionary];
    viewPthProperties[kSAEventPropertyElementPath] = elementPath;

    return viewPthProperties.count > 0 ? viewPthProperties : nil;
}

- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    if (![view isKindOfClass:UIView.class] || !self.visualPropertiesTracker) {
        return completionHandler(nil);
    }

    @try {
        [self.visualPropertiesTracker visualPropertiesWithView:view completionHandler:completionHandler];
    } @catch (NSException *exception) {
        SALogError(@"visualPropertiesWithView error: %@", exception);
        completionHandler(nil);
    }
}

- (void)queryVisualPropertiesWithConfigs:(NSArray<NSDictionary *> *)propertyConfigs completionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    if (propertyConfigs.count == 0 || !self.visualPropertiesTracker) {
        return completionHandler(nil);
    }
    
    @try {
        [self.visualPropertiesTracker queryVisualPropertiesWithConfigs:propertyConfigs completionHandler:completionHandler];
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

- (void)dealloc {
    // 断开连接，防止 visualizedConnection 内 timer 导致无法释放
    [self.visualizedConnection close];
}

@end
