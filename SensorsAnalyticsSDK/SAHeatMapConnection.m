//
//  SAHeatMapConnection.m,
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "SAHeatMapConnection.h"
#import "SAHeatMapMessage.h"
#import "SAHeatMapSnapshotMessage.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"

@interface SAHeatMapConnection ()

@end

@implementation SAHeatMapConnection {
    BOOL _connected;

    NSURL *_url;
    NSDictionary *_typeToMessageClassMap;
    NSOperationQueue *_commandQueue;
    UIView *_recordingView;
    NSTimer *timer;
    id<SAHeatMapMessage> _designerMessage;
    NSString *_featureCode;
    NSString *_postUrl;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            SAHeatMapSnapshotRequestMessageType : [SAHeatMapSnapshotRequestMessage class],
        };
        _connected = NO;
        _useGzip = YES;
        _url = url;

        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;
    }

    return self;
}

- (void)close {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)dealloc {
    [self close];
}

- (void)setSessionObject:(id)object forKey:(NSString *)key {
    NSParameterAssert(key != nil);
}

- (id)sessionObjectForKey:(NSString *)key {
    NSParameterAssert(key != nil);
    return key;
}

- (void)sendMessage:(id<SAHeatMapMessage>)message {
    if (_connected) {
        if (_featureCode == nil || _postUrl == nil) {
            return;
        }
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONData:_useGzip withFeatuerCode:_featureCode] encoding:NSUTF8StringEncoding];
        void (^block)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
            
            NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([urlResponse statusCode] == 200) {
                NSData *jsonData = [urlResponseContent dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                int delay = [[dict objectForKey:@"delay"] intValue];
                if (delay < 0) {
                    [self close];
                }
            }
        };
        
        NSURL *URL = [NSURL URLWithString:_postUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
         ^(NSURLResponse *response, NSData* data, NSError *error) {
             return block(data, response, error);
         }];

    } else {
        SADebug(@"Not sending message as we are not connected: %@", [message debugDescription]);
    }
}

- (id <SAHeatMapMessage>)designerMessageForMessage:(id)message {
    NSParameterAssert([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]);

    id <SAHeatMapMessage> designerMessage = nil;

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
   // SADebug(@"%@ VTrack received message: %@", self, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
        NSString *type = messageDictionary[@"type"];
        NSDictionary *payload = messageDictionary[@"payload"];

        designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    } else {
        SAError(@"Badly formed socket message expected JSON dictionary: %@", error);
    }

    return designerMessage;
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        SADebug(@"Canceled to open HeatMap ...");
        [self close];
    } else {
        SADebug(@"Confirmed to open HeatMap ...");
    }
}

#pragma mark -  Methods

- (void)startHeatMapTimer:(id)message withFeatureCode:(NSString *)featureCode withUrl:(NSString *)postUrl {
    _featureCode = featureCode;
    _postUrl =  (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,(__bridge CFStringRef)postUrl, CFSTR(""),CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    _designerMessage = [self designerMessageForMessage:message];

    if (timer) {
        [timer invalidate];
        timer = nil;
    }

    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(handleMessage)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)handleMessage {
    if (_designerMessage) {
        NSOperation *commandOperation = [_designerMessage responseCommandWithConnection:self];
        if (commandOperation) {
            [_commandQueue addOperation:commandOperation];
        }
    }
}

- (void)showOpenHeatMapDialog:(NSString *)featureCode withUrl:(NSString *)postUrl isWifi:(BOOL)isWifi {
    
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
    //文件路径
    NSString *jsonPath = [sensorsBundle pathForResource:@"sa_headmap_path.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    _commandQueue.suspended = NO;
    if (!_connected) {
        _connected = YES;
        
        NSString *alertTitle = @"提示";
        NSString *alertMessage = @"正在连接 APP 点击分析";
        if (!isWifi) {
            alertMessage = @"正在连接 APP 点击分析，建议在 WiFi 环境下使用";
        }
        
        if (@available(iOS 8.0,*)) {
            UIWindow *mainWindow = UIApplication.sharedApplication.keyWindow;
            if (mainWindow == nil) {
                mainWindow = [[UIApplication sharedApplication] delegate].window;
            }
            if (mainWindow == nil) {
                return;
            }
            
            UIAlertController *connectAlert = [UIAlertController
                                               alertControllerWithTitle:alertTitle
                                               message:alertMessage
                                               preferredStyle:UIAlertControllerStyleAlert];
            
            [connectAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                SADebug(@"Canceled to open HeatMap ...");
                
                [self close];
            }]];
            
            [connectAlert addAction:[UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                SADebug(@"Confirmed to open HeatMap ...");
                
                self->_connected = YES;
                [self startHeatMapTimer:jsonString withFeatureCode:featureCode withUrl:postUrl];
            }]];
            
            UIViewController *viewController = mainWindow.rootViewController;
            while (viewController.presentedViewController) {
                viewController = viewController.presentedViewController;
            }
            [viewController presentViewController:connectAlert animated:YES completion:nil];
        } else {
            _connected = YES;
            
            [self startHeatMapTimer:jsonString withFeatureCode:featureCode withUrl:postUrl];

            UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续", nil];
            [connectAlert show];
        }
    } else {
        [self startHeatMapTimer:jsonString withFeatureCode:featureCode withUrl:postUrl];
    }
}

@end

