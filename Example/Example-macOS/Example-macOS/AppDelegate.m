//
//  AppDelegate.m
//  example-macOS
//
//  Created by 陈玉国 on 2025/3/5.
//

#import "AppDelegate.h"
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:@"http://10.1.137.85:8106/sa?project=default" launchOptions:nil];
    options.enableLog = YES;
    options.enableJavaScriptBridge = YES;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
