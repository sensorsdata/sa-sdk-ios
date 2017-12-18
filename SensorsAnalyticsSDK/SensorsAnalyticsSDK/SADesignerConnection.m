//
//  SADesignerConnection.,
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
/// Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "SADesignerConnection.h"
#import "SADesignerDeviceInfoMessage.h"
#import "SADesignerDisconnectMessage.h"
#import "SADesignerEventBindingMessage.h"
#import "SADesignerMessage.h"
#import "SADesignerSnapshotMessage.h"
#import "SADesignerSessionCollection.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK.h"

@interface SADesignerConnection () <SAWebSocketDelegate>

@end

@implementation SADesignerConnection {
    /* The difference between _open and _connected is that open
     is set when the socket is open, and _connected is set when
     we actually have started sending/receiving messages from
     the server. A connection can become _open/not _open in quick
     succession if the websocket proxy rejects the request, but
     we will only try and reconnect if we were actually _connected.
     */
    BOOL _open;
    BOOL _connected;

    NSURL *_url;
    NSMutableDictionary *_session;
    NSDictionary *_typeToMessageClassMap;
    SAWebSocket *_webSocket;
    NSOperationQueue *_commandQueue;
    UIView *_recordingView;
    void (^_connectCallback)(void);
    void (^_disconnectCallback)(void);
}

- (instancetype)initWithURL:(NSURL *)url
                 keepTrying:(BOOL)keepTrying
            connectCallback:(void (^)(void))connectCallback
         disconnectCallback:(void (^)(void))disconnectCallback {
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            SADesignerDeviceInfoRequestMessageType : [SADesignerDeviceInfoRequestMessage class],
            SADesignerDisconnectMessageType : [SADesignerDisconnectMessage class],
            SADesignerEventBindingRequestMessageType : [SADesignerEventBindingRequestMessage class],
            SADesignerSnapshotRequestMessageType : [SADesignerSnapshotRequestMessage class],
        };

        _open = NO;
        _connected = NO;
        _sessionEnded = NO;
        _useGzip = NO;
        _session = [[NSMutableDictionary alloc] init];
        _url = url;
        _connectCallback = connectCallback;
        _disconnectCallback = disconnectCallback;

        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;

        if (keepTrying) {
            [self open:YES maxInterval:15 maxRetries:999];
        } else {
            [self open:YES maxInterval:0 maxRetries:0];
        }
    }

    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    return [self initWithURL:url keepTrying:NO connectCallback:nil disconnectCallback:nil];
}


- (void)open:(BOOL)initiate maxInterval:(int)maxInterval maxRetries:(int)maxRetries {
    static int retries = 0;
    BOOL inRetryLoop = retries > 0;

    SADebug(@"In open. initiate = %d, retries = %d, maxRetries = %d, maxInterval = %d, connected = %d", initiate, retries, maxRetries, maxInterval, _connected);

    if (self.sessionEnded || _connected || (inRetryLoop && retries >= maxRetries) ) {
        // break out of retry loop if any of the success conditions are met.
        retries = 0;
    } else if (initiate ^ inRetryLoop) {
        // If we are initiating a new connection, or we are already in a
        // retry loop (but not both). Then open a socket.
        if (!_open) {
            SADebug(@"Attempting to open WebSocket to: %@, try %d/%d ", _url, retries, maxRetries);
            _open = YES;
            _webSocket = [[SAWebSocket alloc] initWithURL:_url];
            _webSocket.delegate = self;
            [_webSocket open];
        }
        if (retries < maxRetries) {
            __weak SADesignerConnection *weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                SADesignerConnection *strongSelf = weakSelf;
                [strongSelf open:NO maxInterval:maxInterval maxRetries:maxRetries];
            });
            retries++;
        }
    }
}

- (void)close {
    [_webSocket close];
    for (NSString *key in [_session keyEnumerator]) {
        id value = [_session valueForKey:key];
        if ([value conformsToProtocol:@protocol(SADesignerSessionCollection)]) {
            [value cleanup];
        }
    }
    _session = [[NSMutableDictionary alloc] init];
}

- (void)dealloc {
    _webSocket.delegate = nil;
    [self close];
}

- (void)setSessionObject:(id)object forKey:(NSString *)key {
    NSParameterAssert(key != nil);

    @synchronized (_session) {
        _session[key] = object ?: [NSNull null];
    }
}

- (id)sessionObjectForKey:(NSString *)key {
    NSParameterAssert(key != nil);

    @synchronized (_session) {
        id object = _session[key];
        return [object isEqual:[NSNull null]] ? nil : object;
    }
}

- (void)sendMessage:(id<SADesignerMessage>)message {
    if (_connected) {
    
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONData:_useGzip] encoding:NSUTF8StringEncoding];
//        SADebug(@"%@ VTrack sending message: %@", self, [message description]);
        [_webSocket send:jsonString];
    } else {
        SADebug(@"Not sending message as we are not connected: %@", [message debugDescription]);
    }
}

- (id <SADesignerMessage>)designerMessageForMessage:(id)message {
    NSParameterAssert([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]);

    id <SADesignerMessage> designerMessage = nil;

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
//    SADebug(@"%@ VTrack received message: %@", self, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
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
        SADebug(@"Canceled to connect VTrack ...");
        _sessionEnded = YES;
        [self close];
    } else {
        SADebug(@"Confirmed to connect VTrack ...");
    }
}

#pragma mark - SAWebSocketDelegate Methods

- (void)handleMessage:(id)message {
    id<SADesignerMessage> designerMessage = [self designerMessageForMessage:message];
    NSOperation *commandOperation = [designerMessage responseCommandWithConnection:self];
    if (commandOperation) {
        [_commandQueue addOperation:commandOperation];
    }
}

- (void)webSocket:(SAWebSocket *)webSocket didReceiveMessage:(id)message {
    if (!_connected) {
        _connected = YES;
        
        NSString *alertTitle = @"Connecting to VTrack";
        NSString *alertMessage = @"正在连接到 Sensors Analytics 可视化埋点管理界面...";
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            UIWindow *mainWindow = [SensorsAnalyticsSDK sharedInstance].vtrackWindow;
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
                SADebug(@"Canceled to connect VTrack ...");
                
                _sessionEnded = YES;
                [self close];
            }]];
            
            [connectAlert addAction:[UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                SADebug(@"Confirmed to connect VTrack ...");
                
                _connected = YES;
                
                if (_connectCallback) {
                    _connectCallback();
                }
                
                [self handleMessage:message];
            }]];
            
            [[mainWindow rootViewController] presentViewController:connectAlert animated:YES completion:nil];
        } else {
            _connected = YES;
            
            if (_connectCallback) {
                _connectCallback();
            }
            
            [self handleMessage:message];

            UIAlertView *connectAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续", nil];
            [connectAlert show];
        }
    } else {
        [self handleMessage:message];
    }
}

- (void)webSocketDidOpen:(SAWebSocket *)webSocket {
    _commandQueue.suspended = NO;
}

- (void)webSocket:(SAWebSocket *)webSocket didFailWithError:(NSError *)error {
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self open:YES maxInterval:15 maxRetries:999];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

- (void)webSocket:(SAWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    SADebug(@"WebSocket did close with code '%d' reason '%@'.", (int)code, reason);
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self open:YES maxInterval:15 maxRetries:999];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

@end

