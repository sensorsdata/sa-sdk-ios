//
// SAAppClickTracker.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2021/4/27.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAAppClickTracker.h"
#import "SensorsAnalyticsSDK+Private.h"
#import "SAConstants+Private.h"
#import "SAAutoTrackProperty.h"
#import "SAConstants.h"
#import "SAValidator.h"
#import "SAAutoTrackUtils.h"
#import "UIView+SAAutoTrack.h"
#import "UIViewController+SAAutoTrack.h"
#import "SAModuleManager.h"
#import "SALog.h"
#import "SAUIProperties.h"

@interface SAAppClickTracker ()

@property (nonatomic, strong) NSMutableSet<Class> *ignoredViewTypeList;

@end

@implementation SAAppClickTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignoredViewTypeList = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return kSAEventNameAppClick;
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    if ([self isViewControllerIgnored:viewController]) {
        return NO;
    }

    return ![self isBlackListContainsViewController:viewController];
}

#pragma mark - Public Methods

- (void)autoTrackEventWithView:(UIView *)view {
    // 判断时间间隔
    if (![SAAutoTrackUtils isValidAppClickForObject:view]) {
        return;
    }

    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:view viewController:nil];
    if (!properties) {
        return;
    }

    // 保存当前触发时间
    view.sensorsdata_timeIntervalForLastAppClick = [[NSProcessInfo processInfo] systemUptime];

    [self autoTrackEventWithView:view properties:properties];
}

- (void)autoTrackEventWithScrollView:(UIScrollView *)scrollView atIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *properties = [SAAutoTrackUtils propertiesWithAutoTrackObject:(UIScrollView<SAAutoTrackViewProperty> *)scrollView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [SAAutoTrackUtils propertiesWithAutoTrackDelegate:scrollView didSelectedAtIndexPath:indexPath];
    [properties addEntriesFromDictionary:dic];

    // 解析 Cell
    UIView *cell = [SAUIProperties cellWithScrollView:scrollView andIndexPath:indexPath];
    if (!cell) {
        return;
    }

    [self autoTrackEventWithView:cell properties:properties];
}

- (void)autoTrackEventWithGestureView:(UIView *)view {
    NSMutableDictionary *properties = [[SAAutoTrackUtils propertiesWithAutoTrackObject:view] mutableCopy];
    if (properties.count == 0) {
        return;
    }

    [self autoTrackEventWithView:view properties:properties];
}

- (void)trackEventWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    @try {
        if (view == nil) {
            return;
        }
        NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc]init];
        [eventProperties addEntriesFromDictionary:[SAAutoTrackUtils propertiesWithAutoTrackObject:view isCodeTrack:YES]];
        if ([SAValidator isValidDictionary:properties]) {
            [eventProperties addEntriesFromDictionary:properties];
        }

        // 添加自定义属性
        [SAModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
            if (visualProperties) {
                [eventProperties addEntriesFromDictionary:visualProperties];
            }

            [self trackPresetEventWithProperties:eventProperties];
        }];
    } @catch (NSException *exception) {
        SALogError(@"%@: %@", self, exception);
    }
}

- (void)ignoreViewType:(Class)aClass {
    if (!aClass) {
        return;
    }
    [_ignoredViewTypeList addObject:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    for (Class tempClass in self.ignoredViewTypeList) {
        if ([aClass isSubclassOfClass:tempClass]) {
            return YES;
        }
    }
    return NO;
}

- (void)ignoreAppClickOnViews:(NSArray<Class> *)views {
    if (![views isKindOfClass:[NSArray class]]) {
        return;
    }
    [self.ignoredViewTypeList addObjectsFromArray:views];
}

- (BOOL)isIgnoreEventWithView:(UIView *)view {
    UIViewController *viewController = [SAUIProperties findNextViewControllerByResponder:view];
    return self.isIgnored || [self isViewTypeIgnored:[view class]] || [self isViewControllerIgnored:viewController];
}

#pragma mark – Private Methods

- (BOOL)isBlackListContainsViewController:(UIViewController *)viewController {
    NSDictionary *autoTrackBlackList = [self autoTrackViewControllerBlackList];
    NSDictionary *appClickBlackList = autoTrackBlackList[kSAEventNameAppClick];
    return [self isViewController:viewController inBlackList:appClickBlackList];
}

- (void)autoTrackEventWithView:(UIView *)view properties:(NSDictionary<NSString *, id> * _Nullable)properties {
    if (self.isIgnored || view.sensorsdata_isIgnored) {
        return;
    }

    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    [SAModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
        if (visualProperties) {
            [eventProperties addEntriesFromDictionary:visualProperties];
        }

        [self trackAutoTrackEventWithProperties:eventProperties];
    }];
}

@end
