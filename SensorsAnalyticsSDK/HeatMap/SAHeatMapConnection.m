//
//  SAHeatMapConnection.m,
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAHeatMapConnection.h"
#import "SAHeatMapMessage.h"
#import "SAHeatMapSnapshotMessage.h"
#import "SALogger.h"
#import "SensorsAnalyticsSDK+Private.h"

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
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONData:_useGzip featuerCode:_featureCode] encoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL URLWithString:_postUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSessionDataTask *task = [[SensorsAnalyticsSDK sharedInstance].network dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (response.statusCode == 200) {
                NSData *jsonData = [urlResponseContent dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                int delay = [[dict objectForKey:@"delay"] intValue];
                if (delay < 0) {
                    [self close];
                }
            }
        }];
        [task resume];

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

#pragma mark -  Methods

- (void)startHeatMapTimer:(id)message withFeatureCode:(NSString *)featureCode withUrl:(NSString *)postUrl {
    _featureCode = featureCode;
    _postUrl =  (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)postUrl, CFSTR(""),  CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
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

- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)postUrl {
    
    NSBundle *sensorsBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[SensorsAnalyticsSDK class]] pathForResource:@"SensorsAnalyticsSDK" ofType:@"bundle"]];
    //文件路径
    NSString *jsonPath = [sensorsBundle pathForResource:@"sa_headmap_path.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    _commandQueue.suspended = NO;
    if (!self->_connected) {
        self->_connected = YES;
        [self startHeatMapTimer:jsonString withFeatureCode:featureCode withUrl:postUrl];
    } else {
        [self startHeatMapTimer:jsonString withFeatureCode:featureCode withUrl:postUrl];
    }
}

@end

