//
//  SADesignerEventBindingMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/18/16.
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
///  Created by Amanda Canyon on 11/18/14.
///  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "SAAbstractDesignerMessage.h"
#import "SADesignerSessionCollection.h"

# pragma mark -- EventBinding Request

extern NSString *const SADesignerEventBindingRequestMessageType;

@interface SADesignerEventBindingRequestMessage : SAAbstractDesignerMessage

@end

# pragma mark -- EventBinding Response

@interface SADesignerEventBindingResponseMessage : SAAbstractDesignerMessage

+ (instancetype)message;

@property (nonatomic, copy) NSString *status;

@end

# pragma mark -- DebugTrack

@interface SADesignerTrackMessage : SAAbstractDesignerMessage

+ (instancetype)messageWithPayload:(NSDictionary *)payload;

@end

# pragma mark -- EventBinding Collection

@interface SAEventBindingCollection : NSObject<SADesignerSessionCollection>

@property (nonatomic, readonly) NSMutableSet *bindings;

- (instancetype)initWithEvents:(NSMutableSet *)bindings;

- (void)updateBindingsWithPayload:(NSArray *)bindingPayload;

@end
