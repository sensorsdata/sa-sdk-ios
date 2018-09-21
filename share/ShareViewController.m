//
//  ShareViewController.m
//  share
//
//  Created by ziven.mac on 2018/1/12.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SAAppExtensionDataManager.h"
#import "ShareViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [[SAAppExtensionDataManager sharedInstance]writeEvent:@"SharedExtensionPost"
                                               properties:@{@"Action":@"Post",@"content":self.contentText?self.contentText :@""}
                                          groupIdentifier:@"group.cn.com.sensorsAnalytics.share"];
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

-(void)didSelectCancel {
    [[SAAppExtensionDataManager sharedInstance]writeEvent:@"SharedExtensionCancel"
                                               properties:@{@"Action":@"Cancel",@"content":self.contentText?self.contentText :@""}
                                          groupIdentifier:@"group.cn.com.sensorsAnalytics.share"];
}
- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
