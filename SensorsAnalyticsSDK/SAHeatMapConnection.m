//
//  SAHeatMapConnection.m,
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
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
//    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"snapshot_request_ios.json"];
//    NSError *err=nil;
//    NSString *message=[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    NSString *message = @"{\"type\":\"snapshot_request\", \"payload\":{\"config\":{\"enums\":[{\"name\":\"UIControlState\", \"flag_set\":true, \"base_type\":\"NSUInteger\", \"values\":[{\"value\":0, \"display_name\":\"Normal\"}, {\"value\":1, \"display_name\":\"Highlighted\"}, {\"value\":2, \"display_name\":\"Disabled\"}, {\"value\":4, \"display_name\":\"Selected\"} ] }, {\"name\":\"UIControlEvents\", \"base_type\":\"NSUInteger\", \"flag_set\":true, \"values\":[{\"value\":1, \"display_name\":\"TouchDown\"}, {\"value\":2, \"display_name\":\"TouchDownRepeat\"}, {\"value\":4, \"display_name\":\"TouchDragInside\"}, {\"value\":8, \"display_name\":\"TouchDragOutside\"}, {\"value\":16, \"display_name\":\"TouchDragEnter\"}, {\"value\":32, \"display_name\":\"TouchDragExit\"}, {\"value\":64, \"display_name\":\"TouchUpInside\"}, {\"value\":128, \"display_name\":\"TouchUpOutside\"}, {\"value\":256, \"display_name\":\"TouchCancel\"}, {\"value\":4096, \"display_name\":\"ValueChanged\"}, {\"value\":65536, \"display_name\":\"EditingDidBegin\"}, {\"value\":131072, \"display_name\":\"EditingChanged\"}, {\"value\":262144, \"display_name\":\"EditingDidEnd\"}, {\"value\":524288, \"display_name\":\"EditingDidEndOnExit\"}, {\"value\":4095, \"display_name\":\"AllTouchEvents\"}, {\"value\":983040, \"display_name\":\"AllEditingEvents\"}, {\"value\":251658240, \"display_name\":\"ApplicationReserved\"}, {\"value\":4026531840, \"display_name\":\"SystemReserved\"}, {\"value\":4294967295, \"display_name\":\"AllEvents\"} ] } ], \"classes\":[{\"name\":\"NSObject\", \"superclass\":null, \"properties\":[] }, {\"name\":\"UIResponder\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIScreen\", \"superclass\":\"NSObject\", \"properties\":[{\"name\":\"bounds\", \"type\":\"CGRect\", \"readonly\":true }, {\"name\":\"applicationFrame\", \"type\":\"CGRect\", \"readonly\":true } ] }, {\"name\":\"UIStoryboardSegueTemplate\", \"superclass\":\"NSObject\", \"properties\":[{\"name\":\"identifier\", \"type\":\"NSString\", \"readonly\":true }, {\"name\":\"viewController\", \"type\":\"UIViewController\"}, {\"name\":\"performOnViewLoad\", \"type\":\"BOOL\"} ] }, {\"name\":\"UINavigationItem\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIBarItem\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIBarButtonItem\", \"superclass\":\"UIBarItem\", \"properties\":[] }, {\"name\":\"UIGestureRecognizer\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIGestureRecognizerTarget\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIView\", \"superclass\":\"UIResponder\", \"properties\":[{\"name\":\"userInteractionEnabled\", \"type\":\"BOOL\"}, {\"name\":\"frame\", \"type\":\"CGRect\"}, {\"name\":\"bounds\", \"type\":\"CGRect\"}, {\"name\":\"transform\", \"type\":\"CGAffineTransform\"}, {\"name\":\"superview\", \"type\":\"UIView\"}, {\"name\":\"window\", \"type\":\"UIWindow\"}, {\"name\":\"subviews\", \"type\":\"NSArray\"}, {\"name\":\"jjf_fingerprintVersion\", \"type\":\"NSArray\", \"use_kvc\":false }, {\"name\":\"jjf_varA\", \"type\":\"NSString\", \"use_kvc\":false },{\"name\":\"sensorsAnalyticsViewID\", \"type\":\"NSString\", \"use_kvc\":false }, {\"name\":\"jjf_varB\", \"type\":\"NSString\", \"use_kvc\":false }, {\"name\":\"jjf_varC\", \"type\":\"NSString\", \"use_kvc\":false }, {\"name\":\"jjf_varSetD\", \"type\":\"NSArray\", \"use_kvc\":false }, {\"name\":\"jjf_varE\", \"type\":\"NSString\", \"use_kvc\":false }, {\"name\":\"restorationIdentifier\", \"type\":\"NSString\"} ] }, {\"name\":\"UILabel\", \"superclass\":\"UIView\", \"properties\":[{\"name\":\"text\", \"type\":\"NSString\"} ] }, {\"name\":\"UIImageView\", \"superclass\":\"UIView\", \"properties\":[] }, {\"name\":\"UIControlTargetAction\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIControl\", \"superclass\":\"UIView\", \"properties\":[{\"name\":\"state\", \"type\":\"UIControlState\"}, {\"name\":\"enabled\", \"type\":\"BOOL\"}, {\"name\":\"allTargets\", \"type\":\"NSSet\"}, {\"name\":\"allControlEvents\", \"type\":\"UIControlEvents\"}, {\"name\":\"_targetActions\", \"type\":\"NSArray\"}, {\"name\":\"nextResponder\", \"type\":\"UIResponder\"} ] }, {\"name\":\"UISwitch\", \"superclass\":\"UIControl\", \"properties\":[] }, {\"name\":\"UIScrollView\", \"superclass\":\"UIView\", \"properties\":[{\"name\":\"contentOffset\", \"type\":\"CGPoint\"}, {\"name\":\"contentSize\", \"type\":\"CGSize\"} ] }, {\"name\":\"UITableView\", \"superclass\":\"UIScrollView\", \"properties\":[{\"name\":\"allowsSelection\", \"type\":\"BOOL\"} ] },{\"name\":\"UICollectionView\", \"superclass\":\"UIScrollView\", \"properties\":[{\"name\":\"allowsSelection\", \"type\":\"BOOL\"} ] }, {\"name\":\"UITextView\", \"superclass\":\"UIScrollView\", \"properties\":[{\"name\":\"text\", \"type\":\"NSString\"} ] }, {\"name\":\"UIButton\", \"superclass\":\"UIControl\", \"properties\":[] }, {\"name\":\"CALayer\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"NSLayoutConstraint\", \"superclass\":\"NSObject\", \"properties\":[] }, {\"name\":\"UIWindow\", \"superclass\":\"UIView\", \"properties\":[{\"name\":\"rootViewController\", \"type\":\"UIViewController\"}, {\"name\":\"screen\", \"type\":\"UIScreen\", \"readonly\":true } ] }, {\"name\":\"UIViewController\", \"superclass\":\"UIResponder\", \"properties\":[{\"name\":\"isViewLoaded\", \"type\":\"BOOL\", \"readonly\":true }, {\"name\":\"view\", \"type\":\"UIView\", \"predicate\":\"self.isViewLoaded == YES\"}, {\"name\":\"restorationIdentifier\", \"type\":\"NSString\"}, {\"name\":\"parentViewController\", \"type\":\"UIViewController\"}, {\"name\":\"presentedViewController\", \"type\":\"UIViewController\"}, {\"name\":\"presentingViewController\", \"type\":\"UIViewController\"}, {\"name\":\"childViewControllers\", \"type\":\"NSArray\"} ] } ] } } }";
    _commandQueue.suspended = NO;
    if (!_connected) {
        _connected = YES;
        
        NSString *alertTitle = @"提示";
        NSString *alertMessage = @"正在连接 APP 点击分析";
        if (!isWifi) {
            alertMessage = @"正在连接 APP 点击分析，建议在 WiFi 环境下使用";
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
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
                
                _connected = YES;
                [self startHeatMapTimer:message withFeatureCode:featureCode withUrl:postUrl];
            }]];
            
            UIViewController *viewController = mainWindow.rootViewController;
            while (viewController.presentedViewController) {
                viewController = viewController.presentedViewController;
            }
            [viewController presentViewController:connectAlert animated:YES completion:nil];
        } else {
            _connected = YES;
            
            [self startHeatMapTimer:message withFeatureCode:featureCode withUrl:postUrl];

            UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续", nil];
            [connectAlert show];
        }
    } else {
        [self startHeatMapTimer:message withFeatureCode:featureCode withUrl:postUrl];
    }
}

@end

