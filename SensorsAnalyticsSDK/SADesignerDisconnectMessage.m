//
//  SADesignerDisconnectMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/28/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//

#import "SADesignerConnection.h"
#import "SADesignerDisconnectMessage.h"

NSString *const SADesignerDisconnectMessageType = @"disconnect";

@implementation SADesignerDisconnectMessage

+ (instancetype)message {
    return [(SADesignerDisconnectMessage *)[self alloc] initWithType:@"disconnect"];
}

- (NSOperation *)responseCommandWithConnection:(SADesignerConnection *)connection {
    __weak SADesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        SADesignerConnection *conn = weak_connection;
        
        conn.sessionEnded = YES;
        [conn close];
    }];
    return operation;
}

@end
