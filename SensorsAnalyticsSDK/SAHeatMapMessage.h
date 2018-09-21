//
//  SAHeatMapMessage.h
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 8/1/17.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SAHeatMapConnection;

@protocol SAHeatMapMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;

- (NSData *)JSONData:(BOOL)useGzip withFeatuerCode:(NSString *)fetureCode;

- (NSOperation *)responseCommandWithConnection:(SAHeatMapConnection *)connection;

@end
