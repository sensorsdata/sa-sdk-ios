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
    void (^_connectCallback)();
    void (^_disconnectCallback)();
}

- (instancetype)initWithURL:(NSURL *)url
                 keepTrying:(BOOL)keepTrying
            connectCallback:(void (^)())connectCallback
         disconnectCallback:(void (^)())disconnectCallback {
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
            [self open:YES maxInterval:30 maxRetries:40];
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

    SALog(@"In open. initiate = %d, retries = %d, maxRetries = %d, maxInterval = %d, connected = %d", initiate, retries, maxRetries, maxInterval, _connected);

    if (self.sessionEnded || _connected || (inRetryLoop && retries >= maxRetries) ) {
        // break out of retry loop if any of the success conditions are met.
        retries = 0;
    } else if (initiate ^ inRetryLoop) {
        // If we are initiating a new connection, or we are already in a
        // retry loop (but not both). Then open a socket.
        if (!_open) {
            SALog(@"Attempting to open WebSocket to: %@, try %d/%d ", _url, retries, maxRetries);
            _open = YES;
            _webSocket = [[SAWebSocket alloc] initWithURL:_url];
            _webSocket.delegate = self;
            [_webSocket open];
        }
        if (retries < maxRetries) {
            __weak SADesignerConnection *weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MIN(pow(1.4, retries), maxInterval) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
    _session = nil;
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
        SADebug(@"%@ VTrack sending message: %@", self, [message description]);
        [_webSocket send:jsonString];
    } else {
        SALog(@"Not sending message as we are not connected: %@", [message debugDescription]);
    }
}

- (id <SADesignerMessage>)designerMessageForMessage:(id)message {
    NSParameterAssert([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSData class]]);

    id <SADesignerMessage> designerMessage = nil;

    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
    SADebug(@"%@ VTrack received message: %@", self, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
        NSString *type = messageDictionary[@"type"];
        NSDictionary *payload = messageDictionary[@"payload"];

        designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    } else {
        SALog(@"Badly formed socket message expected JSON dictionary: %@", error);
    }

    return designerMessage;
}

#pragma mark - MPWebSocketDelegate Methods

- (void)webSocket:(SAWebSocket *)webSocket didReceiveMessage:(id)message {
    if (!_connected) {
        _connected = YES;
        [self showConnectedView];
        if (_connectCallback) {
            _connectCallback();
        }
    }
    id<SADesignerMessage> designerMessage = [self designerMessageForMessage:message];

    NSOperation *commandOperation = [designerMessage responseCommandWithConnection:self];

    if (commandOperation) {
        [_commandQueue addOperation:commandOperation];
    }
}

- (void)webSocketDidOpen:(SAWebSocket *)webSocket {
    SALog(@"WebSocket %@ did open.", webSocket);
    _commandQueue.suspended = NO;
}

- (void)webSocket:(SAWebSocket *)webSocket didFailWithError:(NSError *)error {
    SALog(@"WebSocket did fail with error: %@", error);
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    [self hideConnectedView];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self open:YES maxInterval:10 maxRetries:40];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

- (void)webSocket:(SAWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
    SALog(@"WebSocket did close with code '%d' reason '%@'.", (int)code, reason);

    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    [self hideConnectedView];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self open:YES maxInterval:10 maxRetries:40];
        if (_disconnectCallback) {
            _disconnectCallback();
        }
    }
}

- (void)showConnectedView {
    if(!_recordingView) {
        UIWindow *mainWindow = [[UIApplication sharedApplication] delegate].window;
        _recordingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainWindow.frame.size.width, 1.0)];
        _recordingView.backgroundColor = [UIColor colorWithRed:4/255.0f green:180/255.0f blue:4/255.0f alpha:1.0];
        [mainWindow addSubview:_recordingView];
        [mainWindow bringSubviewToFront:_recordingView];
    }
}

- (void)hideConnectedView {
    if (_recordingView) {
        [_recordingView removeFromSuperview];
    }
    _recordingView = nil;
}

@end

