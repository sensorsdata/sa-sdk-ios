//
//  AppDelegate.m
//  HelloSensorsAnalytics
//
//  Created by 曹犟 on 15/7/4.
//  Copyright (c) 2015年 SensorsData. All rights reserved.
//

#import "AppDelegate.h"
#import "SensorsAnalyticsSDK.h"
#import "SAAppExtensionDataManager.h"
@interface AppDelegate ()

@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SensorsAnalyticsSDK sharedInstanceWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"
                                        andDebugMode:SensorsAnalyticsDebugAndTrack];
    [[SensorsAnalyticsSDK sharedInstance]registerSuperProperties:@{@"AAA":UIDevice.currentDevice.identifierForVendor.UUIDString}];
    [[SensorsAnalyticsSDK sharedInstance] registerDynamicSuperProperties:^NSDictionary * _Nonnull{
        NSMutableSet *mutArr = [NSMutableSet set];
        for (int i=0; i<100; i++) {
            [mutArr addObject:[NSString stringWithFormat:@"%i",i]];
        }
        return @{@"__timstamp__":@((long long)(NSDate.date.timeIntervalSince1970*1000)),
                 @"__APPState__":@(UIApplication.sharedApplication.applicationState),
                 @"$device_id":UIDevice.currentDevice.identifierForVendor.UUIDString,
                 @"count_100":mutArr,
                 };
    }];
    [[SensorsAnalyticsSDK sharedInstance] enableLog:YES];
    [[SensorsAnalyticsSDK sharedInstance] enableAutoTrack:SensorsAnalyticsEventTypeAppStart |
     SensorsAnalyticsEventTypeAppEnd |
     SensorsAnalyticsEventTypeAppViewScreen |
     SensorsAnalyticsEventTypeAppClick];

    [[SensorsAnalyticsSDK sharedInstance] setMaxCacheSize:20000];
    [[SensorsAnalyticsSDK sharedInstance] enableHeatMap];
    [[SensorsAnalyticsSDK sharedInstance] trackInstallation:@"AppInstall" withProperties:@{@"testValue" : @"testKey"}];
    //[[SensorsAnalyticsSDK sharedInstance] addHeatMapViewControllers:[NSArray arrayWithObject:@"DemoController"]];
    [[SensorsAnalyticsSDK sharedInstance] trackAppCrash];
    [[SensorsAnalyticsSDK sharedInstance] setFlushNetworkPolicy:SensorsAnalyticsNetworkTypeALL];
    [[SensorsAnalyticsSDK sharedInstance] addWebViewUserAgentSensorsDataFlag];
    [[SensorsAnalyticsSDK sharedInstance] enableTrackScreenOrientation:YES];
    [[SensorsAnalyticsSDK sharedInstance] enableTrackGPSLocation:YES];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([[SensorsAnalyticsSDK sharedInstance] handleHeatMapUrl:url]) {
        return YES;
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //@"group.cn.com.sensorsAnalytics.share"
    [[SensorsAnalyticsSDK sharedInstance]trackEventFromExtensionWithGroupIdentifier:@"group.cn.com.sensorsAnalytics.share" completion:^(NSString *identifiy ,NSArray *events){
        
    }];
//   NSArray  *eventArray = [[SAAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier: @"group.cn.com.sensorsAnalytics.share"];
//    NSLog(@"applicationDidBecomeActive::::::%@",eventArray);
//    for (NSDictionary *dict in eventArray  ) {
//        [[SensorsAnalyticsSDK sharedInstance]track:dict[@"event"] withProperties:dict[@"properties"]];
//    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[[SAAppExtensionDataManager sharedInstance]deleteEventsWithGroupIdentifier:@"dd"];
    //[[SAAppExtensionDataManager sharedInstance]readAllEventsWithGroupIdentifier:NULL];
    //[[SAAppExtensionDataManager sharedInstance]writeEvent:@"eee" properties:@"" groupIdentifier:@"ff"];
    //[[SAAppExtensionDataManager sharedInstance]fileDataCountForGroupIdentifier:@"ff"];
    //[[SAAppExtensionDataManager sharedInstance]fileDataArrayWithPath:@"fff" limit:-1];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
